import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apps_model.dart';
import 'glance.dart';
import 'native.dart';
import 'rail.dart';
import 'style.dart';

/// One row of the App List: a letter header or an app.
class _Row {
  final String? header;
  final AppEntry? app;
  const _Row.header(String this.header) : app = null;
  const _Row.app(AppEntry this.app) : header = null;
  double get extent => header != null ? kHeader : kRow;
}

/// The Home: Glance, Favorites, App List, Alphabet Rail, Search.
class HomeScreen extends StatefulWidget {
  final AppsModel model;
  const HomeScreen({super.key, required this.model});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  final _focus = FocusNode();
  late final AppLifecycleListener _life;

  bool _searching = false;
  String _query = '';

  // Alphabet Rail touch.
  RailGeometry? _geo;
  String? _railLetter; // letter under the finger (or last one touched)
  double? _bendY; // finger y while on the rail; letters bend around it
  int? _hover; // app index in the Section View under the finger

  // Layout of the scrolling App List, rebuilt every build.
  Map<String, double> _sectionTop = const {};
  double _listStart = 0;

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

  // ── Navigation ──────────────────────────────────────────────────────────

  void _closeSearch() {
    _search.clear();
    _focus.unfocus();
    if (_searching || _query.isNotEmpty) {
      setState(() {
        _searching = false;
        _query = '';
      });
    }
  }

  void _openSearch() {
    if (_searching) return;
    HapticFeedback.lightImpact();
    setState(() => _searching = true);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  /// Home pressed (or back): close Search and return to the Glance.
  void _goHome() {
    _closeSearch();
    Navigator.of(context).popUntil((r) => r.isFirst);
    if (_scroll.hasClients) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic);
    }
  }

  void _launch(AppEntry a) {
    Native.launch(a.component);
    if (_searching) {
      Future.delayed(const Duration(milliseconds: 400), _closeSearch);
    }
  }

  // ── Alphabet Rail touch ─────────────────────────────────────────────────

  /// Top of the Section View's first app row (header sits on ★'s line).
  double get _sectionRowsTop => _geo!.starY - 31 + kHeader;

  void _railAt(Offset p) {
    final geo = _geo;
    if (geo == null || geo.letters.isEmpty) return;
    final width = MediaQuery.sizeOf(context).width;
    if (p.dx >= width - kRailHit - 8 || _railLetter == null) {
      // On the rail: pick the nearest letter.
      final l = geo.letters[geo.indexAt(p.dy)];
      if (l != _railLetter) HapticFeedback.selectionClick();
      setState(() {
        _railLetter = l;
        _bendY = p.dy;
        _hover = null;
      });
    } else {
      // Slid left into the Section View: hover the app under the finger.
      final apps = model.sectionOf(_railLetter!);
      final i = ((p.dy - _sectionRowsTop) / kRow).floor();
      final h = (i >= 0 && i < apps.length) ? i : null;
      if (h != _hover) {
        if (h != null) HapticFeedback.selectionClick();
        setState(() => _hover = h);
      }
    }
  }

  void _railEnd() {
    final letter = _railLetter;
    final hover = _hover;
    setState(() {
      _railLetter = null;
      _bendY = null;
      _hover = null;
    });
    if (letter == null) return;
    final apps = model.sectionOf(letter);
    if (hover != null && hover < apps.length) {
      _launch(apps[hover]);
      return;
    }
    // Released on the rail: jump the App List so that section sits where
    // the Section View showed it.
    if (!_scroll.hasClients) return;
    final double target = letter == '★'
        ? 0.0
        : _listStart + (_sectionTop[letter] ?? 0) - (_geo!.starY - 31);
    _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
  }

  // ── App Menu ────────────────────────────────────────────────────────────

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

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final mq = MediaQuery.of(context);
        final geo = RailGeometry.of(model.railLetters, mq.size,
            bottomInset: mq.padding.bottom);
        _geo = geo;
        final glanceH = mq.size.height * 0.367;
        final favs = model.favorites;

        final rows = <_Row>[];
        final tops = <String, double>{};
        var y = 0.0;
        model.sections.forEach((letter, apps) {
          tops[letter] = y;
          rows.add(_Row.header(letter));
          y += kHeader;
          for (final a in apps) {
            rows.add(_Row.app(a));
            y += kRow;
          }
        });
        _sectionTop = tops;
        _listStart = glanceH + favs.length * kRow + kGap;
        final touching = _railLetter != null;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (_, _) => _goHome(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            body: _searching
                ? _searchView()
                : Stack(children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: touching ? 0 : 1,
                        child: _homeList(glanceH, favs, rows, mq.size.height),
                      ),
                    ),
                    if (touching) Positioned.fill(child: _sectionView()),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AlphabetRail(
                            geo: geo, fingerY: _bendY, active: _railLetter),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: geo.top,
                      width: kRailHit,
                      height: geo.bottom - geo.top,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanDown: (d) => _railAt(d.globalPosition),
                        onPanUpdate: (d) => _railAt(d.globalPosition),
                        onPanEnd: (_) => _railEnd(),
                        onPanCancel: _railEnd,
                      ),
                    ),
                  ]),
          ),
        );
      },
    );
  }

  Widget _homeList(
      double glanceH, List<AppEntry> favs, List<_Row> rows, double screenH) {
    return NotificationListener<OverscrollNotification>(
      // Pulling down at the top opens Search.
      onNotification: (n) {
        if (n.overscroll < -2 && n.dragDetails != null) _openSearch();
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
            itemExtent: kRow,
            delegate: SliverChildBuilderDelegate(
              (c, i) => _appRow(favs[i]),
              childCount: favs.length,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: kGap,
              child: favs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(left: kLabelX),
                      child: Text('Long-press an app to pin it',
                          style: kLabel.copyWith(
                              fontSize: 13, color: const Color(0x99FFFFFF))),
                    )
                  : null,
            ),
          ),
          SliverVariedExtentList(
            itemExtentBuilder: (i, _) => rows[i].extent,
            delegate: SliverChildBuilderDelegate(
              (c, i) => rows[i].header != null
                  ? _headerRow(rows[i].header!)
                  : _appRow(rows[i].app!),
              childCount: rows.length,
            ),
          ),
          // Lets the last sections scroll up to the rail's ★ line too.
          SliverToBoxAdapter(child: SizedBox(height: screenH * 0.6)),
        ],
      ),
    );
  }

  /// While the finger is on the rail: only the touched letter's apps,
  /// header on ★'s line, ready to slide-to-launch.
  Widget _sectionView() {
    final letter = _railLetter!;
    final apps = model.sectionOf(letter);
    return Stack(children: [
      Positioned(
        left: 0,
        right: 0,
        top: _geo!.starY - 31,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerRow(letter),
            for (var i = 0; i < apps.length; i++)
              _appRow(apps[i], hover: i == _hover, interactive: false),
            if (apps.isEmpty)
              SizedBox(
                height: kRow,
                child: Padding(
                  padding: const EdgeInsets.only(left: kLabelX, top: 18),
                  child: Text('Long-press an app to pin it',
                      style: kLabel.copyWith(color: const Color(0x99FFFFFF))),
                ),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _headerRow(String letter) => SizedBox(
        height: kHeader,
        child: Padding(
          padding: const EdgeInsets.only(left: kHeaderX, top: 21),
          child: Text(letter, style: kHeaderText),
        ),
      );

  Widget _appRow(AppEntry a, {bool hover = false, bool interactive = true}) {
    final row = SizedBox(
      height: kRow,
      child: Row(children: [
        const SizedBox(width: kDotX - 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: hover ? Colors.white : kDotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: kLabelX - kDotX - 5),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            style: hover
                ? kLabel.copyWith(fontSize: 18, fontWeight: FontWeight.w500)
                : kLabel,
            child: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: kRailHit),
      ]),
    );
    if (!interactive) return row;
    return InkWell(
      onTap: () => _launch(a),
      onLongPress: () => _menu(a),
      child: row,
    );
  }

  // ── Search ──────────────────────────────────────────────────────────────

  Widget _searchView() {
    final res = model.search(_query);
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0x99000000)),
      child: SafeArea(
        child: Column(children: [
          Expanded(
            child: _query.isEmpty
                ? const SizedBox.shrink()
                : res.isEmpty
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              kLabelX, 0, 32, 16),
                          child: Text('No apps match "$_query"',
                              style: kLabel.copyWith(
                                  color: const Color(0x99FFFFFF))),
                        ),
                      )
                    // Reversed: the top match sits right above the field.
                    : ListView.builder(
                        reverse: true,
                        itemExtent: kRow,
                        itemCount: res.length,
                        itemBuilder: (c, i) => _appRow(res[i], hover: i == 0),
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0x26FFFFFF),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(children: [
                const SizedBox(width: 18),
                const Icon(Icons.search, color: Color(0xB3FFFFFF)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _search,
                    focusNode: _focus,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.go,
                    cursorColor: Colors.white,
                    style: kLabel.copyWith(fontSize: 17),
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Search apps',
                      hintStyle: TextStyle(color: Color(0x80FFFFFF)),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                    onSubmitted: (_) {
                      final r = model.search(_query);
                      if (r.isNotEmpty) _launch(r.first);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xB3FFFFFF)),
                  onPressed: _closeSearch,
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}
