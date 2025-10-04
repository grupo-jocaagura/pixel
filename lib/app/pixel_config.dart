import 'package:flutter/foundation.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../data/gateways/gateway_canvas_impl.dart';
import '../data/repositories/repository_canvas_impl.dart';
import '../domain/gateways/gateway_canvas.dart';
import '../domain/repositories/repository_canvas.dart';
import '../domain/usecases/canvas/canvas_usecases.dart';
import '../ui/pages/pages.dart';
import 'blocs/bloc_canvas.dart';
import 'blocs/bloc_canvas_preview.dart';

enum AppMode { dev, qa, prod }

final PixelConfig pixelConfig = PixelConfig();
final List<OnboardingStep> onboardingSteps = <OnboardingStep>[
  OnboardingStep(
    title: 'Probando',
    autoAdvanceAfter: const Duration(seconds: 5),
    description: 'Probando funcion del onboarding, simulando carga del tema',
    onEnter: () async {
      return Right<ErrorItem, Unit>(Unit.value);
    },
  ),
  OnboardingStep(
    title: 'Probando',
    autoAdvanceAfter: const Duration(seconds: 3),
    description: 'Probando funcion del onboarding, simulando carga del canvas',
    onEnter: () async {
      return Right<ErrorItem, Unit>(Unit.value);
    },
  ),
];

class PixelConfig {
  PixelConfig() {
    _init();
  }

  final BlocLoading blocLoading = BlocLoading();
  void _init() {}

  AppConfig dev() {
    return _commonConfig(
      serviceWsDatabase: FakeServiceWsDatabase(),
      serviceSession: FakeServiceSession(),
    );
  }

  AppConfig qa() {
    return _commonConfig(
      serviceWsDatabase:
          FakeServiceWsDatabase(), // reemplazar por los respectivos servicios
      serviceSession:
          FakeServiceSession(), // reemplazar por los respectivos servicios
    );
  }

  AppConfig prod() {
    return _commonConfig(
      serviceWsDatabase:
          FakeServiceWsDatabase(), // reemplazar por los respectivos servicios
      serviceSession:
          FakeServiceSession(), // reemplazar por los respectivos servicios
    );
  }

  AppConfig _commonConfig({
    required ServiceWsDatabase<Map<String, dynamic>> serviceWsDatabase,
    required ServiceSession serviceSession,
  }) {
    final RepositoryAuth repository = RepositoryAuthImpl(
      gateway: GatewayAuthImpl(serviceSession),
    );

    final BlocSession blocSession = BlocSession.fromRepository(
      repository: repository,
    );

    final GatewayCanvas gatewayCanvas = GatewayCanvasImpl(serviceWsDatabase);
    final RepositoryCanvas repositoryCanvas = RepositoryCanvasImpl(
      gatewayCanvas,
    );
    final BlocCanvas blocCanvas = BlocCanvas(
      usecases: CanvasUsecases.fromRepo(repositoryCanvas),
      blocLoading: blocLoading,
    );

    final Map<String, BlocModule> blocModuleList = <String, BlocModule>{
      BlocCanvas.name: blocCanvas,
      BlocCanvasPreview.name: BlocCanvasPreview(),
      BlocSession.name: blocSession,
    };

    return AppConfig(
      blocLoading: blocLoading,
      blocTheme: BlocTheme(
        themeUsecases: ThemeUsecases.fromRepo(
          RepositoryThemeImpl(gateway: GatewayThemeImpl()),
        ),
      ),
      blocUserNotifications: BlocUserNotifications(),
      blocMainMenuDrawer: BlocMainMenuDrawer(),
      blocSecondaryMenuDrawer: BlocSecondaryMenuDrawer(),
      blocResponsive: BlocResponsive(),
      blocOnboarding: BlocOnboarding(),
      pageManager: PageManager(initial: navStackModel),
      blocModuleList: blocModuleList,
    );
  }

  AppConfig byMode(AppMode mode) {
    switch (mode) {
      case AppMode.prod:
        debugPrint('// TODO(albert): implementar prod(); por ahora usa dev()');
        return prod();
      case AppMode.qa:
        debugPrint('// TODO(albert): implementar qa(); por ahora usa dev()');
        return qa();
      case AppMode.dev:
        return dev();
    }
  }
}
