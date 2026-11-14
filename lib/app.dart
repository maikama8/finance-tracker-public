import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/providers.dart';
import 'ui/shell/app_shell.dart';
import 'ui/theme/app_theme.dart';

/// Root widget. The shell waits on the ledger and picks the theme.
class KoboApp extends ConsumerWidget {
  const KoboApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Kobo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const AppShell(),
    );
  }
}
