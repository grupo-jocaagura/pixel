import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import 'app/app_state_manager.dart';
import 'app/blocs/bloc_canvas.dart';
import 'data/gateways/gateway_canvas_impl.dart';
import 'data/repositories/repository_canvas_impl.dart';
import 'domain/gateways/gateway_canvas.dart';
import 'domain/repositories/repository_canvas.dart';
import 'domain/usecases/canvas/canvas_usecases.dart';
import 'ui/navigation/app_navigator.dart';
import 'ui/navigation/app_route.dart';

final BlocLoading blocLoading = BlocLoading();
final GatewayCanvas gatewayCanvas = GatewayCanvasImpl(FakeServiceWsDatabase());
final RepositoryCanvas repositoryCanvas = RepositoryCanvasImpl(gatewayCanvas);
void main() => runApp(
  AppStateManager(
    blocCanvas: BlocCanvas(
      usecases: CanvasUsecases.fromRepo(repositoryCanvas),
      blocLoading: blocLoading,
    ),
    child: MaterialApp(
      title: 'Pixel',
      initialRoute: AppRoute.home.path,
      onGenerateRoute: AppNavigator().onGenerateRoute,
    ),
  ),
);
