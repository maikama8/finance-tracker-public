enum ThemePreference { system, light, dark }

ThemePreference parseThemePreference(String value) {
  return switch (value) {
    'system' => ThemePreference.system,
    'light' => ThemePreference.light,
    'dark' => ThemePreference.dark,
    _ => throw ArgumentError.value(value, 'value', 'unknown theme'),
  };
}
