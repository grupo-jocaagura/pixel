import 'package:flutter/material.dart';

import 'blocs/bloc_canvas.dart';

class AppStateManager extends InheritedWidget {
  const AppStateManager({
    required super.child,
    required this.blocCanvas,
    super.key,
  });

  final BlocCanvas blocCanvas;

  static AppStateManager of(BuildContext context) {
    final AppStateManager? result = context
        .dependOnInheritedWidgetOfExactType<AppStateManager>();
    assert(result != null, 'No AppStateManager found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
