/// How Kobo chooses light and dark.
enum ThemePreference { system, light, dark }

/// Reads the theme name stored in the settings row.
ThemePreference parseThemePreference(String value) {
  return switch (value) {
    'system' => ThemePreference.system,
    'light' => ThemePreference.light,
    'dark' => ThemePreference.dark,
    _ => throw ArgumentError.value(value, 'value', 'unknown theme'),
  };
}
