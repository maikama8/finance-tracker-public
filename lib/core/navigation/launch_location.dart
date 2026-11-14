import '../theme/theme_preference.dart';

/// Where the web app should open, from the URL hash.
class LaunchLocation {
  const LaunchLocation({required this.tab, this.themeOverride});

  final int tab;
  final ThemePreference? themeOverride;

  static const home = LaunchLocation(tab: 0);
}

LaunchLocation parseLaunchLocation(String location) {
  final raw = location.isEmpty ? '/' : location;
  final uri = Uri.parse(raw.startsWith('/') ? raw : '/$raw');
  final tab = switch (uri.path) {
    '/activity' || '/transactions' => 1,
    '/budgets' => 2,
    '/accounts' => 3,
    '/settings' => 4,
    _ => 0,
  };
  final theme = switch (uri.queryParameters['theme']) {
    'dark' => ThemePreference.dark,
    'light' => ThemePreference.light,
    _ => null,
  };
  return LaunchLocation(tab: tab, themeOverride: theme);
}

String pathForTab(int tab) {
  return switch (tab) {
    1 => '/activity',
    2 => '/budgets',
    3 => '/accounts',
    4 => '/settings',
    _ => '/dashboard',
  };
}
