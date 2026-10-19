import 'dart:async';

import 'package:flutter/foundation.dart';

import 'kanji.dart';
import 'native.dart';

class AppsModel extends ChangeNotifier {
  StreamSubscription<String>? _sub;

  List<AppEntry> apps = const [];
  List<String> _favorites = [];
  DateTime? nextAlarm;
  bool isDefaultHome = true;
  KanjiEntry? kanji;

  /// Bumped when the user asks to see the Kanji Card (widget tap).
  final ValueNotifier<int> kanjiRequested = ValueNotifier(0);

  /// False until the user has been through the Favorites picker once.
  bool favoritesChosen = true;

  /// Apps grouped by rail letter, in rail order ('#' first, then A–Z).
  Map<String, List<AppEntry>> sections = const {};

  /// Bumped every time the home button is pressed while Kawa is on top.
  final ValueNotifier<int> homePressed = ValueNotifier(0);

  Future<void> init() async {
    try {
      final f = await Native.getFavorites();
      favoritesChosen = f != null;
      _favorites = f ?? [];
    } catch (e) {
      debugPrint('kawa: favorites unavailable: $e');
    }
    _sub = Native.events.listen((e) {
      switch (e) {
        case 'apps':
          refreshApps();
        case 'alarm':
          refreshAlarm();
        case 'home':
          homePressed.value++;
        case 'role':
          refreshRole();
        case 'kanji':
          kanjiRequested.value++;
      }
    });
    await Future.wait(
        [refreshApps(), refreshAlarm(), refreshRole(), refreshKanji()]);
    try {
      if (await Native.takeLaunchedForKanji()) kanjiRequested.value++;
    } catch (_) {}
  }

  Future<void> refreshApps() async {
    final list = await Native.apps()
      ..add(const AppEntry('uz.abduvaliy.kawa', Native.settingsComponent,
          'Kawa Settings'));
    list.sort((a, b) {
      final ga = a.letter == '#' ? 0 : 1, gb = b.letter == '#' ? 0 : 1;
      if (ga != gb) return ga - gb;
      return a.label.toLowerCase().compareTo(b.label.toLowerCase());
    });
    apps = list;
    final s = <String, List<AppEntry>>{};
    for (final a in list) {
      (s[a.letter] ??= []).add(a);
    }
    sections = s;
    // Favorites whose app is gone drop out quietly.
    final installed = {for (final a in apps) a.package};
    final kept = _favorites.where(installed.contains).toList();
    if (kept.length != _favorites.length) {
      _favorites = kept;
      await Native.setFavorites(_favorites);
    }
    notifyListeners();
  }

  Future<void> refreshKanji() async {
    try {
      final k = await KanjiEntry.now();
      if (k?.kanji != kanji?.kanji) {
        kanji = k;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('kawa: kanji unavailable: $e');
    }
  }

  Future<void> refreshRole() async {
    try {
      final held = await Native.isDefaultHome();
      if (held != isDefaultHome) {
        isDefaultHome = held;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> refreshAlarm() async {
    try {
      nextAlarm = await Native.nextAlarm();
    } catch (_) {
      nextAlarm = null;
    }
    notifyListeners();
  }

  /// ★ followed by every letter that has at least one app.
  List<String> get railLetters => ['★', ...sections.keys];

  List<AppEntry> get favorites {
    final byPkg = <String, AppEntry>{};
    for (final a in apps) {
      byPkg.putIfAbsent(a.package, () => a);
    }
    return [for (final p in _favorites) if (byPkg[p] != null) byPkg[p]!];
  }

  /// Apps shown when the finger rests on [letter]; ★ means Favorites.
  List<AppEntry> sectionOf(String letter) =>
      letter == '★' ? favorites : (sections[letter] ?? const []);

  bool isFavorite(String package) => _favorites.contains(package);

  List<String> get favoritePackages => List.of(_favorites);

  /// Replaces Favorites with [packages], in that order.
  Future<void> setFavorites(List<String> packages) async {
    _favorites = List.of(packages);
    favoritesChosen = true;
    notifyListeners();
    await Native.setFavorites(_favorites);
  }

  Future<void> toggleFavorite(String package) async {
    if (!_favorites.remove(package)) _favorites.add(package);
    notifyListeners();
    await Native.setFavorites(_favorites);
  }

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
    kanjiRequested.dispose();
    super.dispose();
  }
}
