import 'package:flutter/material.dart';

import '../business/db/store.dart';
import 'home.dart';
import 'theme/app_theme.dart';

class CopydApp extends StatelessWidget {
  const CopydApp({super.key});

  ThemeMode _themeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Store.instance,
      builder: (BuildContext context, Widget? _) {
        return MaterialApp(
          title: 'CopyD',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: _themeMode(Store.instance.themeMode),
          home: const HomeShell(),
        );
      },
    );
  }
}
