import 'package:flutter/material.dart';

import 'app_route.dart';

class AppNavigator {
  factory AppNavigator() => AppNavigator._();
  AppNavigator._();

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final AppRoute route = AppRoute.values.firstWhere(
      (AppRoute route) => route.path == settings.name,
      orElse: () => AppRoute.notFound,
    );

    return MaterialPageRoute<Widget>(
      settings: settings,
      builder: route.builder,
    );
  }
}
