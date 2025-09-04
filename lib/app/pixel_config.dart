import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../data/gateways/gateway_canvas_impl.dart';
import '../data/repositories/repository_canvas_impl.dart';
import '../domain/gateways/gateway_canvas.dart';
import '../domain/repositories/repository_canvas.dart';
import '../domain/usecases/canvas/canvas_usecases.dart';
import '../ui/pages/pages.dart';
import 'blocs/bloc_canvas.dart';

enum AppMode { dev, qa, prod }

final PixelConfig pixelConfig = PixelConfig();
final List<OnboardingStep> onboardingSteps = <OnboardingStep>[
  OnboardingStep(
    title: 'Probando',
    autoAdvanceAfter: const Duration(seconds: 5),
    description: 'Probando funcion del onboarding, simulando carga del canvas',
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
    final GatewayCanvas gatewayCanvas = GatewayCanvasImpl(
      FakeServiceWsDatabase(),
    );
    final RepositoryCanvas repositoryCanvas = RepositoryCanvasImpl(
      gatewayCanvas,
    );
    final BlocCanvas blocCanvas = BlocCanvas(
      usecases: CanvasUsecases.fromRepo(repositoryCanvas),
      blocLoading: blocLoading,
    );

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
      blocModuleList: <String, BlocModule>{BlocCanvas.name: blocCanvas},
    );
  }
}
