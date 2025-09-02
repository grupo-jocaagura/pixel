import 'package:flutter/material.dart';

import '../pages/home_page.dart';
import '../pages/not_found_route_page.dart';
import '../pages/speak_the_canvas_page.dart';

enum AppRoute { home, notFound, speakTheCanvas }

extension AppRouteExtension on AppRoute {
  /// El “path” que usará Navigator
  String get path {
    switch (this) {
      case AppRoute.home:
        return '/';
      case AppRoute.speakTheCanvas:
        return '/speak-the-canvas';
      case AppRoute.notFound:
        return '/not-found';
    }
  }

  /// El builder de la pantalla correspondiente
  WidgetBuilder get builder {
    switch (this) {
      case AppRoute.home:
        return (BuildContext _) => const HomePage();
      case AppRoute.speakTheCanvas:
        return (BuildContext _) =>
            const SpeakTheCanvasPage(); // Placeholder for actual view
      case AppRoute.notFound:
        return (BuildContext _) => const NotFoundRoutePage();
    }
  }
}
