import 'package:flutter/material.dart';
import 'package:jocaagura_domain/jocaagura_domain.dart';

import 'app/app_state_manager.dart';
import 'app/blocs/bloc_canvas.dart';
import 'app/blocs/bloc_loading.dart';
import 'data/gateways/gateway_canvas_impl.dart';
import 'data/repositories/repository_canvas_impl.dart';
import 'domain/gateways/gateway_canvas.dart';
import 'domain/repositories/repository_canvas.dart';
import 'domain/usecases/canvas/batch_remove_pixels_usecase.dart';
import 'domain/usecases/canvas/batch_upsert_pixel_usecase.dart';
import 'domain/usecases/canvas/clear_canvas_usecase.dart';
import 'domain/usecases/canvas/create_canvas_usecase.dart';
import 'domain/usecases/canvas/load_canvas_usecase.dart';
import 'domain/usecases/canvas/remove_pixel_usecase.dart';
import 'domain/usecases/canvas/save_canvas_usecase.dart';
import 'domain/usecases/canvas/upsert_pixel_usecase.dart';
import 'domain/usecases/canvas/watch_canvas_usecase.dart';
import 'ui/navigation/app_navigator.dart';
import 'ui/navigation/app_route.dart';

final BlocLoading blocLoading = BlocLoading();
final GatewayCanvas gatewayCanvas = GatewayCanvasImpl(FakeServiceWsDatabase());
final RepositoryCanvas repositoryCanvas = RepositoryCanvasImpl(gatewayCanvas);
void main() => runApp(
  AppStateManager(
    blocCanvas: BlocCanvas(
      upsertPixelUseCase: UpsertPixelUseCase(repositoryCanvas),
      clearCanvasUseCase: ClearCanvasUseCase(repositoryCanvas),
      blocLoading: blocLoading,
      loadUseCase: LoadCanvasUseCase(repositoryCanvas),
      saveUseCase: SaveCanvasUseCase(repositoryCanvas),
      createUseCase: CreateCanvasUseCase(repositoryCanvas),
      removePixelUseCase: RemovePixelUseCase(repositoryCanvas),
      watchCanvasUseCase: WatchCanvasUseCase(repositoryCanvas),
      batchRemovePixelsUseCase: BatchRemovePixelsUseCase(repositoryCanvas),
      batchUpsertPixelsUseCase: BatchUpsertPixelsUseCase(repositoryCanvas),
    ),
    child: MaterialApp(
      title: 'Pixel',
      initialRoute: AppRoute.home.path,
      onGenerateRoute: AppNavigator().onGenerateRoute,
    ),
  ),
);
