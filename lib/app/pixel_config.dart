import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../data/gateways/gateway_canvas_impl.dart';
import '../data/repositories/repository_canvas_impl.dart';
import '../data/services/firebase_service_session.dart';
import '../data/services/google_sheets/coalesced_token_provider.dart';
import '../data/services/google_sheets/google_sheets_canvas_db.dart';
import '../domain/gateways/gateway_canvas.dart';
import '../domain/repositories/repository_canvas.dart';
import '../domain/usecases/canvas/canvas_usecases.dart';
import '../ui/pages/home_page.dart';
import '../ui/pages/pages.dart';
import '../ui/pages/session/login_page.dart';
import 'blocs/bloc_canvas.dart';
import 'blocs/bloc_canvas_preview.dart';
import 'env.dart';

enum AppMode { dev, qa, prod }

final PixelConfig pixelConfig = PixelConfig();

class PixelConfig {
  PixelConfig() {
    _init();
  }

  final BlocLoading blocLoading = BlocLoading();
  void _init() {}

  static const int kAuthRouteDebounceMs = 120;
  static const int kAuthRefreshDebounceMs = 900;

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
    final AppConfig app = AppConfig(
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
    _installAuthNavigatorSync(app.pageManager, blocSession);

    return app;
  }

  void _installAuthNavigatorSync(
    PageManager pageManager,
    BlocSession blocSession, {
    int debounceMs = kAuthRouteDebounceMs,
  }) {
    final Debouncer debouncer = Debouncer(milliseconds: debounceMs);

    void reroute(SessionState state) {
      debouncer(() {
        final PageModel target = blocSession.isAuthenticated
            ? HomePage.pageModel
            : LoginPage.pageModel;

        pageManager.pushDistinctTop(target);
      });
    }

    reroute(blocSession.stateOrDefault);

    blocSession.stream.listen(reroute);
  }

  AppConfig dev() => _commonConfig(
    serviceWsDatabase: FakeServiceWsDatabase(),
    serviceSession: FakeServiceSession(),
  );

  AppConfig qa() {
    final FirebaseServiceSession serviceSession = FirebaseServiceSession(
      googleClientId: Env.googleClientId,
    );
    serviceSession.processRedirectResultOnce();

    final ServiceWsDatabase<Map<String, dynamic>> serviceWsDatabase =
        GoogleSheetsCanvasDb(
          tokenProvider: () => serviceSession.sheetsAccessToken(),
          spreadsheetTitleOrId: 'Pixel - Mis Canvases',
        );

    return _commonConfig(
      serviceWsDatabase: serviceWsDatabase,
      serviceSession: serviceSession,
    );
  }

  AppConfig prod() {
    final FirebaseServiceSession serviceSession = FirebaseServiceSession(
      googleClientId: Env.googleClientId,
    );

    final ServiceWsDatabase<Map<String, dynamic>> serviceWsDatabase =
        GoogleSheetsCanvasDb(
          tokenProvider: CoalescedTokenProvider(
            () => serviceSession.sheetsAccessToken(),
          ).call,
          spreadsheetTitleOrId: 'Pixel - Mis Canvases',
        );

    return _commonConfig(
      serviceWsDatabase: serviceWsDatabase,
      serviceSession: serviceSession,
    );
  }

  AppConfig byMode(AppMode mode) {
    switch (mode) {
      case AppMode.prod:
        return prod();
      case AppMode.qa:
        return qa();
      case AppMode.dev:
        return dev();
    }
  }
}
