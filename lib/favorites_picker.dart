import 'package:flutter/material.dart';

import 'apps_model.dart';
import 'native.dart';

/// Opens the Favorites picker. Back leaves Favorites unchosen (the picker
/// comes back next launch); "Skip" and "Pin" record the choice.
Future<void> openFavoritesPicker(BuildContext context, AppsModel model) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => FavoritesPicker(model: model),
    ));

/// Tap apps in the order they should appear under the clock.
class FavoritesPicker extends StatefulWidget {
  final AppsModel model;
  const FavoritesPicker({super.key, required this.model});

  @override
  State<FavoritesPicker> createState() => _FavoritesPickerState();
}

class _FavoritesPickerState extends State<FavoritesPicker> {
  late final List<String> _picked = widget.model.favoritePackages;
  String _query = '';

  void _toggle(String package) => setState(() {
        if (!_picked.remove(package)) _picked.add(package);
      });

  Future<void> _finish(List<String> packages) async {
    await widget.model.setFavorites(packages);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const dim = Color(0x99FFFFFF);
    final q = _query.trim().toLowerCase();
    // One row per package; Kawa Settings can't be a Favorite.
    final seen = <String>{};
    final apps = [
      for (final a in widget.model.apps)
        if (a.component != Native.settingsComponent &&
            seen.add(a.package) &&
            (q.isEmpty || a.label.toLowerCase().contains(q)))
          a,
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Choose your Favorites'),
        actions: [
          TextButton(
            onPressed: () => _finish(const []),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text(
            'Tap apps in the order you want them under the clock. '
            'You can change this later: long-press any app.',
            style: TextStyle(color: dim),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: 'Search apps',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0x1AFFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: apps.length,
            itemBuilder: (c, i) {
              final a = apps[i];
              final n = _picked.indexOf(a.package);
              return ListTile(
                title: Text(a.label),
                trailing: n < 0
                    ? const Icon(Icons.add_circle_outline, color: dim)
                    : CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Text('${n + 1}',
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600)),
                      ),
                onTap: () => _toggle(a.package),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _finish(_picked),
              child: Text(_picked.isEmpty
                  ? 'Done'
                  : 'Pin ${_picked.length} app${_picked.length == 1 ? '' : 's'}'),
            ),
          ),
        ),
      ]),
    );
  }
}
