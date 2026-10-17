// dynamic_color speaks material_ui's ColorScheme; only its seed Color crosses over.
import 'package:dynamic_color/dynamic_color.dart' show DynamicColorBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apps_model.dart';
import 'home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final model = AppsModel();
  // A Home that never draws is a bricked phone: always reach runApp.
  try {
    await model.init();
  } catch (e) {
    debugPrint('kawa: init failed: $e');
  }
  runApp(KawaApp(model: model));
}

class KawaApp extends StatelessWidget {
  final AppsModel model;
  const KawaApp({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (_, dark) {
        final scheme = ColorScheme.fromSeed(
          seedColor: dark?.primary ?? const Color(0xFF7FB8D8),
          brightness: Brightness.dark,
        );
        return MaterialApp(
          title: 'Kawa',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: ThemeData(colorScheme: scheme, useMaterial3: true),
          theme: ThemeData(colorScheme: scheme, useMaterial3: true),
          color: Colors.transparent,
          home: HomeScreen(model: model),
        );
      },
    );
  }
}
