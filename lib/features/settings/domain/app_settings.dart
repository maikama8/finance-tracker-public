import '../../../core/currency/currency.dart';
import '../../../core/theme/theme_preference.dart';

class AppSettings {
  const AppSettings({
    this.baseCurrencyCode = Currencies.defaultBase,
    this.theme = ThemePreference.light,
    this.seeded = false,
  });

  final String baseCurrencyCode;
  final ThemePreference theme;
  final bool seeded;

  AppSettings copyWith({
    String? baseCurrencyCode,
    ThemePreference? theme,
    bool? seeded,
  }) {
    return AppSettings(
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
      theme: theme ?? this.theme,
      seeded: seeded ?? this.seeded,
    );
  }
}
