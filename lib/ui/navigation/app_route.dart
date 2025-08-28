import 'package:flutter/material.dart';

import '../views/home_view.dart';
import '../views/not_found_route_widget_view.dart';
import '../views/speak_the_canvas_view.dart';

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
        return (BuildContext _) => const HomeView();
      case AppRoute.speakTheCanvas:
        return (BuildContext _) =>
            const SpeakTheCanvasView(); // Placeholder for actual view
      case AppRoute.notFound:
        return (BuildContext _) => const NotFoundRouteWidget();
    }
  }
}
