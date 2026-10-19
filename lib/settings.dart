import 'package:flutter/material.dart';

import 'apps_model.dart';
import 'favorites_picker.dart';
import 'native.dart';

/// Kawa's own Settings: default Home app, and what Kawa is.
class SettingsScreen extends StatefulWidget {
  final AppsModel model;
  const SettingsScreen({super.key, required this.model});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    widget.model.refreshRole();
    Native.version().then((v) {
      if (mounted) setState(() => _version = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const dim = Color(0x99FFFFFF);
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Kawa Settings'),
      ),
      body: ListenableBuilder(
        listenable: widget.model,
        builder: (context, _) {
          final isHome = widget.model.isDefaultHome;
          return ListView(children: [
            if (!isHome)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Set Kawa as default home'),
                  onPressed: Native.requestDefaultHome,
                ),
              ),
            ListTile(
              leading: Icon(isHome ? Icons.check_circle : Icons.home_outlined),
              title: const Text('Default home app'),
              subtitle: Text(isHome
                  ? 'Kawa is your home screen. Tap to switch to another launcher.'
                  : 'Another launcher is your home screen right now.',
                  style: const TextStyle(color: dim)),
              onTap: Native.requestDefaultHome,
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Choose Favorites'),
              subtitle: const Text('Pick and order the apps under the clock.',
                  style: TextStyle(color: dim)),
              onTap: () => openFavoritesPicker(context, widget.model),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Icons.wifi_off),
              title: const Text('Offline'),
              subtitle: const Text(
                  'Kawa has no internet permission. Nothing leaves your phone.',
                  style: TextStyle(color: dim)),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('Kawa $_version'),
              subtitle: const Text('GPL-3.0 · Montserrat font: SIL OFL 1.1',
                  style: TextStyle(color: dim)),
              onLongPress: () => showLicensePage(
                  context: context, applicationName: 'Kawa'),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text('川  Kawa means "river".',
                  style: t.bodySmall?.copyWith(color: dim)),
            ),
          ]);
        },
      ),
    );
  }
}
