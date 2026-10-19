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
  /// 'home' (home button pressed while Kawa is the top activity),
  /// 'role' (the default Home app may have changed),
  /// 'kanji' (the Kanji of the Hour widget was tapped while Kawa was running).
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

  /// Pinned packages in order, or null if the user never chose any yet.
  /// Always a fresh growable copy: the decoded list is fixed-length.
  static Future<List<String>?> getFavorites() async {
    final l = await _m.invokeListMethod<String>('getFavorites');
    return l == null ? null : List<String>.of(l);
  }

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

  /// Pseudo-app in the App List that opens Kawa's own Settings.
  static const settingsComponent = 'kawa:settings';

  static Future<bool> isDefaultHome() async =>
      await _m.invokeMethod<bool>('isDefaultHome') ?? false;

  /// Asks Android to make Kawa the Home; if it already is, opens the system
  /// Home picker so the user can switch to another launcher.
  static Future<void> requestDefaultHome() =>
      _m.invokeMethod('requestDefaultHome');

  static Future<String> version() async =>
      await _m.invokeMethod<String>('version') ?? '?';

  /// Kanji of the Hour as JSON (one entry of assets/kanji.json).
  static Future<String?> kanjiNow() => _m.invokeMethod<String>('kanjiNow');

  /// True once if Kawa was cold-started by tapping the widget.
  static Future<bool> takeLaunchedForKanji() async =>
      await _m.invokeMethod<bool>('takeLaunchedForKanji') ?? false;

  static Future<void> openClock() => _m.invokeMethod('openClock');
  static Future<void> openAlarms() => _m.invokeMethod('openAlarms');
}
