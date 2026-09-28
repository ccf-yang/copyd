import 'package:flutter/material.dart';

/// 设计稿色板（与 ui-design.html 一一对应）。
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4F5BFF);
  static const Color primary2 = Color(0xFF8B5CF6);
  static const Color ink = Color(0xFF0E1220);
  static const Color muted = Color(0xFF8A90A6);
  static const Color success = Color(0xFF12B76A);
  static const Color danger = Color(0xFFF04438);
  static const Color warning = Color(0xFFF79009);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[primary, primary2],
  );

  /// 模板首字母头像的渐变色（按 colorSeed 取用）。
  static const List<List<Color>> seedPalette = <List<Color>>[
    <Color>[Color(0xFF5B64FF), Color(0xFF8B5CF6)],
    <Color>[Color(0xFF12B76A), Color(0xFF31D98A)],
    <Color>[Color(0xFFF79009), Color(0xFFFDB022)],
    <Color>[Color(0xFFF04438), Color(0xFFF97066)],
    <Color>[Color(0xFF0BA5EC), Color(0xFF36BFFA)],
    <Color>[Color(0xFF7A5AF8), Color(0xFFA48AFB)],
  ];

  static List<Color> seedFor(int seed) =>
      seedPalette[seed.abs() % seedPalette.length];
}

/// 随明暗主题切换的语义色。
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.line,
    required this.line2,
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.muted2,
    required this.primarySoft,
    required this.varBg,
    required this.varBorder,
    required this.dangerSoft,
    required this.successSoft,
    required this.amberSoft,
    required this.overlay,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color line;
  final Color line2;
  final Color ink;
  final Color ink2;
  final Color muted;
  final Color muted2;
  final Color primarySoft;
  final Color varBg;
  final Color varBorder;
  final Color dangerSoft;
  final Color successSoft;
  final Color amberSoft;
  final Color overlay;

  bool get isDark => brightness == Brightness.dark;

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF6F7FB),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF3F4F9),
    line: Color(0xFFE9EBF2),
    line2: Color(0xFFF1F3F8),
    ink: Color(0xFF0E1220),
    ink2: Color(0xFF39415A),
    muted: Color(0xFF8A90A6),
    muted2: Color(0xFFAAB0C2),
    primarySoft: Color(0xFFEEF0FF),
    varBg: Color(0xFFF5F6FF),
    varBorder: Color(0xFFE2E5FF),
    dangerSoft: Color(0xFFFDEcea),
    successSoft: Color(0xFFE7F8EF),
    amberSoft: Color(0xFFFFF4E5),
    overlay: Color(0x6B0E1220),
  );

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0F1220),
    surface: Color(0xFF181B2A),
    surface2: Color(0xFF202436),
    line: Color(0xFF262A3D),
    line2: Color(0xFF1F2334),
    ink: Color(0xFFEDEFF7),
    ink2: Color(0xFFC3C8DD),
    muted: Color(0xFF9AA0B6),
    muted2: Color(0xFF6B7288),
    primarySoft: Color(0xFF20244A),
    varBg: Color(0xFF1B1F3A),
    varBorder: Color(0xFF2A2F55),
    dangerSoft: Color(0xFF3A1D1D),
    successSoft: Color(0xFF12301F),
    amberSoft: Color(0xFF3A2A12),
    overlay: Color(0x99000000),
  );
}

/// 统一圆角与间距。
class AppRadius {
  AppRadius._();
  static const double card = 16;
  static const double button = 18;
  static const double chip = 12;
  static const double sheet = 26;
}

ThemeData buildAppTheme(Brightness brightness) {
  final AppPalette p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;

  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.primary2,
    surface: p.surface,
    error: AppColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.surface,
    dividerColor: p.line,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: p.ink,
      titleTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: p.ink,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionHandleColor: AppColors.primary,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: TextStyle(color: p.surface),
    ),
  );
}
