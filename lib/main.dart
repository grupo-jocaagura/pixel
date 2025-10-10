import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import 'app/bootstrap/firebase_bootstrap.dart';
import 'app/env.dart';
import 'app/pixel_config.dart';
import 'ui/pages/pages.dart';
import 'ui/pages/splash_screen_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebaseIfNeeded();
  final AppConfig appCfg = pixelConfig.byMode(Env.mode);
  runApp(
    JocaaguraApp(
      appManager: AppManager(appCfg),
      registry: pageRegistry,
      initialLocation: SplashScreenPage.pageModel.toUriString(),
    ),
  );
}

extension PageManagerDebugX on PageManager {
  void debugLogStack([String tag = '']) {
    final String chain = stack.pages.map((PageModel p) => p.name).join(' > ');
    debugPrint('[STACK$tag] $chain');
  }
}
