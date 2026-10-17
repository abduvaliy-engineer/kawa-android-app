import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'native.dart';

/// Rail order: ★ (Favorites), # (non A–Z), then A–Z.
const railLetters = [
  '★', '#', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

class AppsModel extends ChangeNotifier {
  static const _favKey = 'favorites';

  /// Null if storage failed; Kawa still runs, Favorites just aren't saved.
  SharedPreferences? _prefs;
  StreamSubscription<String>? _sub;

  List<AppEntry> apps = const [];
  List<String> _favorites = [];
  DateTime? nextAlarm;
  final Map<String, Future<Uint8List?>> _icons = {};

  /// Bumped every time the home button is pressed while Kawa is on top.
  final ValueNotifier<int> homePressed = ValueNotifier(0);

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _favorites = _prefs!.getStringList(_favKey) ?? [];
    } catch (e) {
      debugPrint('kawa: favorites storage unavailable: $e');
    }
    _sub = Native.events.listen((e) {
      switch (e) {
        case 'apps':
          _icons.clear();
          refreshApps();
        case 'alarm':
          refreshAlarm();
        case 'home':
          homePressed.value++;
      }
    });
    await Future.wait([refreshApps(), refreshAlarm()]);
  }

  Future<void> refreshApps() async {
    final list = await Native.apps();
    list.sort((a, b) {
      final ga = a.letter == '#' ? 0 : 1, gb = b.letter == '#' ? 0 : 1;
      if (ga != gb) return ga - gb;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    apps = list;
    // Favorites whose app is gone drop out quietly.
    final installed = {for (final a in apps) a.package};
    final kept = _favorites.where(installed.contains).toList();
    if (kept.length != _favorites.length) {
      _favorites = kept;
      await _prefs?.setStringList(_favKey, _favorites);
    }
    notifyListeners();
  }

  Future<void> refreshAlarm() async {
    nextAlarm = await Native.nextAlarm();
    notifyListeners();
  }

  List<AppEntry> get favorites {
    final byPkg = <String, AppEntry>{};
    for (final a in apps) {
      byPkg.putIfAbsent(a.package, () => a);
    }
    return [for (final p in _favorites) if (byPkg[p] != null) byPkg[p]!];
  }

  bool isFavorite(String package) => _favorites.contains(package);

  Future<void> toggleFavorite(String package) async {
    if (!_favorites.remove(package)) _favorites.add(package);
    await _prefs?.setStringList(_favKey, _favorites);
    notifyListeners();
  }

  Future<Uint8List?> icon(AppEntry a) =>
      _icons.putIfAbsent(a.component, () => Native.icon(a.component));

  /// Index of the first app filed under [letter], or -1 if none.
  int firstIndexOf(String letter) => apps.indexWhere((a) => a.letter == letter);

  Set<String> get usedLetters => {for (final a in apps) a.letter};

  /// Name matches: prefix matches first, then word-start, then anywhere.
  List<AppEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final prefix = <AppEntry>[], word = <AppEntry>[], inside = <AppEntry>[];
    for (final a in apps) {
      final l = a.label.toLowerCase();
      if (l.startsWith(q)) {
        prefix.add(a);
      } else if (l.contains(' $q')) {
        word.add(a);
      } else if (l.contains(q)) {
        inside.add(a);
      }
    }
    return [...prefix, ...word, ...inside];
  }

  @override
  void dispose() {
    _sub?.cancel();
    homePressed.dispose();
    super.dispose();
  }
}
