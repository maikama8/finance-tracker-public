import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

SemanticsHandle? webSemanticsHandle;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    webSemanticsHandle = SemanticsBinding.instance.ensureSemantics();
  }
  runApp(const ProviderScope(child: KoboApp()));
}
