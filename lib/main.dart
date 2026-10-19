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
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Montserrat',
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        surface: Color(0xFF1C1C1E),
      ),
      splashFactory: NoSplash.splashFactory,
    );
    return MaterialApp(
      title: 'Kawa',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: theme,
      darkTheme: theme,
      color: Colors.transparent,
      home: HomeScreen(model: model),
    );
  }
}
