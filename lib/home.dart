import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apps_model.dart';
import 'glance.dart';
import 'native.dart';
import 'rail.dart';

/// The Home: Glance, Favorites, App List, Alphabet Rail, Search.
class HomeScreen extends StatefulWidget {
  final AppsModel model;
  const HomeScreen({super.key, required this.model});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Fixed row heights make Alphabet Rail jumps exact arithmetic.
  static const _favRow = 60.0;
  static const _appRow = 60.0;
  static const _gap = 48.0;

  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _focus = FocusNode();
  late final AppLifecycleListener _life;
  String _query = '';

  AppsModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    model.homePressed.addListener(_goHome);
    _life = AppLifecycleListener(onResume: () {
      model.refreshAlarm();
      model.refreshApps();
    });
  }

  @override
  void dispose() {
    model.homePressed.removeListener(_goHome);
    _life.dispose();
    _scroll.dispose();
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _search.clear();
    _focus.unfocus();
    if (_query.isNotEmpty) setState(() => _query = '');
  }

  /// Home pressed (or back): clear Search and return to the Glance.
  void _goHome() {
    _clearSearch();
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    }
  }

  void _launch(AppEntry a) {
    Native.launch(a.component);
    Future.delayed(const Duration(milliseconds: 400), _clearSearch);
  }

  void _jump(String letter, double glanceH) {
    if (!_scroll.hasClients) return;
    if (letter == '★') {
      _scroll.jumpTo(0);
      return;
    }
    // Empty letters jump to the next letter that has apps.
    var i = -1;
    for (var k = railLetters.indexOf(letter);
        k < railLetters.length && i < 0;
        k++) {
      i = model.firstIndexOf(railLetters[k]);
    }
    if (i < 0) return;
    final target =
        glanceH + model.favorites.length * _favRow + _gap + i * _appRow;
    _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
  }

  void _menu(AppEntry a) {
    HapticFeedback.mediumImpact();
    final fav = model.isFavorite(a.package);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(a.label,
                style: Theme.of(c).textTheme.titleLarge,
                textAlign: TextAlign.center),
          ),
          ListTile(
            leading: Icon(fav ? Icons.star : Icons.star_border),
            title: Text(fav ? 'Unpin from Favorites' : 'Pin to Favorites'),
            onTap: () {
              Navigator.pop(c);
              model.toggleFavorite(a.package);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App info'),
            onTap: () {
              Navigator.pop(c);
              Native.appInfo(a.component);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Uninstall'),
            onTap: () {
              Navigator.pop(c);
              Native.uninstall(a.package);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final scheme = Theme.of(context).colorScheme;
        final glanceH = MediaQuery.sizeOf(context).height * 0.42;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, _) => _goHome(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(children: [
                  Expanded(
                    child: Stack(children: [
                      Positioned.fill(
                        child: _query.isEmpty
                            ? _homeList(glanceH, scheme)
                            : _results(scheme),
                      ),
                      if (_query.isEmpty)
                        Positioned(
                          right: 6,
                          top: 24,
                          bottom: 12,
                          child: AlphabetRail(
                            enabled: model.usedLetters,
                            accent: scheme.primary,
                            onLetter: (l) => _jump(l, glanceH),
                          ),
                        ),
                    ]),
                  ),
                  _searchBar(scheme),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _homeList(double glanceH, ColorScheme scheme) {
    final favs = model.favorites;
    final apps = model.apps;
    return NotificationListener<OverscrollNotification>(
      // Swipe down at the top focuses Search.
      onNotification: (n) {
        if (n.overscroll < 0 && n.dragDetails != null && !_focus.hasFocus) {
          _focus.requestFocus();
        }
        return false;
      },
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(
            parent: ClampingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: glanceH, child: Glance(model: model)),
          ),
          SliverFixedExtentList(
            itemExtent: _favRow,
            delegate: SliverChildBuilderDelegate(
              (c, i) => _favTile(favs[i]),
              childCount: favs.length,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: _gap,
              child: favs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text('Long-press any app to pin it here',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5))),
                    )
                  : null,
            ),
          ),
          SliverFixedExtentList(
            itemExtent: _appRow,
            delegate: SliverChildBuilderDelegate(
              (c, i) => _appTile(apps[i], scheme,
                  letter: i == 0 || apps[i - 1].letter != apps[i].letter
                      ? apps[i].letter
                      : null),
              childCount: apps.length,
            ),
          ),
          // Lets the last letters scroll up to the top too.
          SliverToBoxAdapter(
            child: SizedBox(height: max(0, glanceH)),
          ),
        ],
      ),
    );
  }

  Widget _results(ColorScheme scheme) {
    final res = model.search(_query);
    if (res.isEmpty) {
      return Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
          child: Text('No apps match "$_query"',
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withValues(alpha: 0.6))),
        ),
      );
    }
    // Reversed: the top match sits right above the Search bar (thumb).
    return ListView.builder(
      reverse: true,
      itemExtent: _appRow,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: res.length,
      itemBuilder: (c, i) => _appTile(res[i], scheme, highlight: i == 0),
    );
  }

  Widget _favTile(AppEntry a) {
    return InkWell(
      onTap: () => _launch(a),
      onLongPress: () => _menu(a),
      child: Padding(
        padding: const EdgeInsets.only(left: 32, right: 56),
        child: Row(children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Text(
              a.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _appTile(AppEntry a, ColorScheme scheme,
      {String? letter, bool highlight = false}) {
    return InkWell(
      onTap: () => _launch(a),
      onLongPress: () => _menu(a),
      child: Container(
        color: highlight ? Colors.white.withValues(alpha: 0.08) : null,
        padding: const EdgeInsets.only(left: 20, right: 56),
        child: Row(children: [
          SizedBox(
            width: 30,
            child: letter == null
                ? null
                : Text(letter,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary)),
          ),
          _AppIcon(future: model.icon(a), size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              a.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 18, color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _searchBar(ColorScheme scheme) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(children: [
            const SizedBox(width: 18),
            Icon(Icons.search, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _search,
                focusNode: _focus,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.go,
                cursorColor: scheme.primary,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                decoration: InputDecoration.collapsed(
                  hintText: 'Search apps',
                  hintStyle:
                      TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                ),
                onChanged: (v) => setState(() => _query = v),
                onSubmitted: (_) {
                  final r = model.search(_query);
                  if (r.isNotEmpty) _launch(r.first);
                },
              ),
            ),
            if (_query.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close,
                    color: Colors.white.withValues(alpha: 0.7)),
                onPressed: _clearSearch,
              )
            else
              const SizedBox(width: 18),
          ]),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final Future<Uint8List?> future;
  final double size;
  const _AppIcon({required this.future, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<Uint8List?>(
        future: future,
        builder: (c, s) => s.data == null
            ? const SizedBox.shrink()
            : Image.memory(s.data!,
                width: size,
                height: size,
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium),
      ),
    );
  }
}
