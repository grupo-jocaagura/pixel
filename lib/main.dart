import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import 'pixel_config.dart';
import 'ui/pages/pages.dart';
import 'ui/pages/splash_screen_page.dart';

void main() => runApp(
  JocaaguraApp(
    appManager: AppManager(pixelConfig.dev()),
    registry: pageRegistry,
    initialLocation: SplashScreenPage.pageModel.toUriString(),
  ),
);

extension PageManagerDebugX on PageManager {
  void debugLogStack([String tag = '']) {
    final String chain = stack.pages.map((PageModel p) => p.name).join(' > ');
    debugPrint('[STACK$tag] $chain');
  }
}
