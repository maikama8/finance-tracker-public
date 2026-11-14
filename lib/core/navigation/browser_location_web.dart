import 'package:web/web.dart';

/// Hash path on web, and `/` on every other target.
String readBrowserLocation() {
  final hash = window.location.hash;
  if (hash.length <= 1) return '/';
  final raw = hash.startsWith('#') ? hash.substring(1) : hash;
  return raw.startsWith('/') ? raw : '/$raw';
}

/// Writes the hash on web. No-op on other targets.
void writeBrowserLocation(String path) {
  final normalized = path.startsWith('/') ? path : '/$path';
  final next = '#$normalized';
  if (window.location.hash == next) return;
  window.location.hash = normalized;
}
