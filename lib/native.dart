import 'package:flutter/services.dart';

/// One launchable app activity on the phone.
class AppEntry {
  final String package;
  final String component;
  final String label;

  const AppEntry(this.package, this.component, this.label);

  /// Alphabet Rail letter this app is filed under: A–Z, or '#' for the rest.
  String get letter {
    if (label.isEmpty) return '#';
    final c = label[0].toUpperCase();
    return RegExp(r'^[A-Z]$').hasMatch(c) ? c : '#';
  }
}

/// Thin wrapper over the Kotlin side (MainActivity.kt). Kawa uses no pub
/// plugins: everything Android-only goes through these two channels.
class Native {
  static const _m = MethodChannel('kawa/apps');
  static const _e = EventChannel('kawa/events');

  /// 'apps' (installed/removed/changed), 'alarm' (next alarm changed),
  /// 'home' (home button pressed while Kawa is the top activity).
  static final Stream<String> events =
      _e.receiveBroadcastStream().map((e) => e as String).asBroadcastStream();

  static Future<List<AppEntry>> apps() async {
    final raw = await _m.invokeListMethod<Map>('apps') ?? const [];
    return [
      for (final m in raw)
        AppEntry(m['package'] as String, m['component'] as String,
            m['label'] as String),
    ];
  }

  static Future<List<String>> getFavorites() async =>
      await _m.invokeListMethod<String>('getFavorites') ?? <String>[];

  static Future<void> setFavorites(List<String> packages) =>
      _m.invokeMethod('setFavorites', {'favorites': packages});

  static Future<void> launch(String component) =>
      _m.invokeMethod('launch', {'component': component});

  static Future<void> appInfo(String component) =>
      _m.invokeMethod('appInfo', {'component': component});

  static Future<void> uninstall(String package) =>
      _m.invokeMethod('uninstall', {'package': package});

  static Future<DateTime?> nextAlarm() async {
    final t = await _m.invokeMethod<int>('nextAlarm');
    return t == null ? null : DateTime.fromMillisecondsSinceEpoch(t);
  }

  static Future<void> openClock() => _m.invokeMethod('openClock');
  static Future<void> openAlarms() => _m.invokeMethod('openAlarms');
}
