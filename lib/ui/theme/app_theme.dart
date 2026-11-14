import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const ink = Color(0xFF10231C);
  static const inkDeep = Color(0xFF0C1411);
  static const leaf = Color(0xFF0E8F5B);
  static const leafBright = Color(0xFF3DDC97);
  static const gold = Color(0xFFC5922C);
  static const cream = Color(0xFFF4F1EA);
  static const card = Color(0xFFFFFCF7);
  static const line = Color(0xFFE3DCD0);
  static const muted = Color(0xFF5E6A64);
  static const expense = Color(0xFFB23A32);
  static const income = Color(0xFF0E7A45);
  static const darkCard = Color(0xFF17211C);
  static const darkLine = Color(0xFF2C3B34);
  static const darkMuted = Color(0xFFA8B5AE);
  static const onDark = Color(0xFFF4F1EA);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: dark ? AppColors.leafBright : AppColors.leaf,
      onPrimary: dark ? AppColors.ink : Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      error: AppColors.expense,
      onError: Colors.white,
      surface: dark ? AppColors.darkCard : AppColors.card,
      onSurface: dark ? AppColors.onDark : AppColors.ink,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? AppColors.inkDeep : AppColors.cream,
    );
    final line = dark ? AppColors.darkLine : AppColors.line;
    final muted = dark ? AppColors.darkMuted : AppColors.muted;
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? AppColors.inkDeep : AppColors.cream,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(color: line, space: 1),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: line),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? AppColors.inkDeep : AppColors.card,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: dark ? AppColors.inkDeep : AppColors.card,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.ink : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      dividerColor: line,
    );
  }
}
