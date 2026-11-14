import 'package:web/web.dart';

String readBrowserLocation() {
  final hash = window.location.hash;
  if (hash.length <= 1) return '/';
  final raw = hash.startsWith('#') ? hash.substring(1) : hash;
  return raw.startsWith('/') ? raw : '/$raw';
}

void writeBrowserLocation(String path) {
  final normalized = path.startsWith('/') ? path : '/$path';
  final next = '#$normalized';
  if (window.location.hash == next) return;
  window.location.hash = normalized;
}
