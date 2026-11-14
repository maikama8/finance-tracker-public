/// Hash path on web, and `/` on every other target.
String readBrowserLocation() => '/';

/// Writes the hash on web. No-op on other targets.
void writeBrowserLocation(String path) {}
