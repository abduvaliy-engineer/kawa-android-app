import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apps_model.dart';

/// Vertical ★ # A–Z strip. Drag or tap to jump; shows a bubble + haptic tick.
class AlphabetRail extends StatefulWidget {
  final Set<String> enabled;
  final ValueChanged<String> onLetter;
  final Color accent;

  const AlphabetRail({
    super.key,
    required this.enabled,
    required this.onLetter,
    required this.accent,
  });

  @override
  State<AlphabetRail> createState() => _AlphabetRailState();
}

class _AlphabetRailState extends State<AlphabetRail> {
  static const _width = 32.0;
  String? _active;
  double _y = 0;

  void _at(double dy, double height) {
    final i = (dy / height * railLetters.length)
        .floor()
        .clamp(0, railLetters.length - 1);
    final l = railLetters[i];
    setState(() => _y = dy.clamp(0, height));
    if (l != _active) {
      _active = l;
      HapticFeedback.selectionClick();
      widget.onLetter(l);
    }
  }

  void _end() => setState(() => _active = null);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final h = c.maxHeight;
      return Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) => _at(d.localPosition.dy, h),
          onVerticalDragUpdate: (d) => _at(d.localPosition.dy, h),
          onVerticalDragEnd: (_) => _end(),
          onTapDown: (d) => _at(d.localPosition.dy, h),
          onTapUp: (_) => _end(),
          onTapCancel: _end,
          child: SizedBox(
            width: _width,
            height: h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final l in railLetters)
                  Text(
                    l,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          l == _active ? FontWeight.w700 : FontWeight.w400,
                      color: l == _active
                          ? widget.accent
                          : Colors.white.withValues(
                              alpha: l == '★' || widget.enabled.contains(l)
                                  ? 0.75
                                  : 0.25),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_active != null)
          Positioned(
            right: _width + 24,
            top: _y - 36,
            child: IgnorePointer(
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.accent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _active!,
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w500,
                      color: Colors.black),
                ),
              ),
            ),
          ),
      ]);
    });
  }
}
