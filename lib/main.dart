import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Kept for the life of the process so web semantics stay enabled.
///
/// Flutter stops updating the semantics tree once every handle is disposed.
/// The web build needs that tree for assistive technology, so this handle is
/// intentionally not disposed.
SemanticsHandle? webSemanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    webSemanticsHandle = SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const ProviderScope(child: KoboApp()));
}
