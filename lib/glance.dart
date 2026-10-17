import 'dart:async';

import 'package:flutter/material.dart';

import 'apps_model.dart';
import 'native.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// Clock, date and next alarm. Tap clock → Clock app, tap alarm → Alarms.
class Glance extends StatefulWidget {
  final AppsModel model;
  const Glance({super.key, required this.model});

  @override
  State<Glance> createState() => _GlanceState();
}

class _GlanceState extends State<Glance> {
  late DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final n = DateTime.now();
      if (n.minute != _now.minute || n.day != _now.day) {
        setState(() => _now = n);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _alarmText(DateTime a) {
    final t = '${_two(a.hour)}:${_two(a.minute)}';
    final today = DateTime(_now.year, _now.month, _now.day);
    final days = DateTime(a.year, a.month, a.day).difference(today).inDays;
    return days == 0 ? t : '${_days[a.weekday - 1]} $t';
  }

  @override
  Widget build(BuildContext context) {
    final fg = Colors.white.withValues(alpha: 0.92);
    final dim = Colors.white.withValues(alpha: 0.7);
    final alarm = widget.model.nextAlarm;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 48, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: Native.openClock,
            child: Text(
              '${_two(_now.hour)}:${_two(_now.minute)}',
              style: TextStyle(
                  fontSize: 76, fontWeight: FontWeight.w200, color: fg,
                  height: 1.0, letterSpacing: -1),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text(
              '${_days[_now.weekday - 1]} ${_now.day} ${_months[_now.month - 1]}',
              style: TextStyle(fontSize: 18, color: dim),
            ),
            if (alarm != null)
              GestureDetector(
                onTap: Native.openAlarms,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('  ·  ⏰ ${_alarmText(alarm)}',
                      style: TextStyle(fontSize: 18, color: dim)),
                ),
              ),
          ]),
        ],
      ),
    );
  }
}
