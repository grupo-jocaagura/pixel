# Autenticación (Camino Feliz) · Pixel al Movimiento

Este README documenta **el flujo de autenticación homologado** usando `jocaagura_domain` + `jocaaguraarchetype` con **FirebaseAuth + Google Sign-In**. Se centra en el **camino feliz**, listo para replicar en QA/Prod, manteniendo **FakeServiceSession** en Dev.

---

## 🧩 Arquitectura (sin tocar el dominio)

```
UI (Splash/Login/Home)
   ↓
AppManager / PageManager (navegación reactiva)
   ↓
BlocSession  (del dominio)
   ↓
RepositoryAuth (del dominio)
   ↓
GatewayAuth   (del dominio)
   ↓
ServiceSession (Fake en dev | Firebase en qa/prod)
```

* **Dev**: `FakeServiceSession()`
* **QA/Prod**: `FirebaseServiceSession(googleClientId: Env.googleClientId)`

---

## ✅ Requisitos

1. **Firebase Console → Authentication → Sign-in method → Google (habilitado)**
2. **Android**: `google-services.json` + SHA-1/256 configurados.
3. **Web/Windows**: usar el **client id web** vía `--dart-define=GOOGLE_CLIENT_ID=...`.
4. **Dominios autorizados** (Web): incluye `localhost`.

---

## 🔧 Variables de entorno (`Env`)

`lib/app/env.dart`

```dart
class Env {
  static const String _mode = String.fromEnvironment('APP_MODE', defaultValue: 'dev');
  static const String googleClientId  = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String firebaseEnv     = String.fromEnvironment('FIREBASE_ENV', defaultValue: 'dev');

  static AppMode get mode {
    switch (_mode) { case 'prod': return AppMode.prod; case 'qa': return AppMode.qa; default: return AppMode.dev; }
  }
}
```

---

## 🚀 Inicialización de Firebase (QA/Prod)

`lib/app/bootstrap/firebase_bootstrap.dart`

```dart
Future<void> initFirebaseIfNeeded() async {
  if (Env.mode == AppMode.dev) return;
  if (Firebase.apps.isNotEmpty) return;

  switch (Env.mode) {
    case AppMode.qa:
      await Firebase.initializeApp(options: fqa.DefaultFirebaseOptions.currentPlatform);
      break;
    case AppMode.prod:
      await Firebase.initializeApp(options: fprod.DefaultFirebaseOptions.currentPlatform);
      break;
    case AppMode.dev:
      break;
  }
}
```

> Dev **no** inicializa Firebase (usa fake).

---

## 🧱 DI y navegación reactiva

`lib/app/pixel_config.dart`

* Construye `BlocSession.fromRepository(...)`.
* Instala **AuthNavigatorSync** que **enruta automáticamente** a `Home` o `Login` cuando cambia el estado de sesión (sin `context`).

```
final AppConfig app = AppConfig(
  // ...
  pageManager: PageManager(initial: navStackModel),
  blocModuleList: {
    BlocCanvas.name: blocCanvas,
    BlocCanvasPreview.name: BlocCanvasPreview(),
    BlocSession.name: blocSession,
  },
);
_installAuthNavigatorSync(app.pageManager, blocSession);

void _installAuthNavigatorSync(PageManager pageManager, BlocSession blocSession, {int debounceMs = 120}) {
  final Debouncer debouncer = Debouncer(milliseconds: debounceMs);
  void reroute(SessionState state) {
    debouncer(() {
      final PageModel target = blocSession.isAuthenticated ? HomePage.pageModel : LoginPage.pageModel;
      pageManager.pushDistinctTop(target);
    });
  }
  reroute(blocSession.stateOrDefault);
  blocSession.stream.listen(reroute);
}
```

### Service por ambiente

```dart
AppConfig dev() => _commonConfig(
  serviceWsDatabase: FakeServiceWsDatabase(),
  serviceSession: FakeServiceSession(),
);

AppConfig qa()  => _commonConfig(
  serviceWsDatabase: FakeServiceWsDatabase(),
  serviceSession: FirebaseServiceSession(googleClientId: Env.googleClientId),
);

AppConfig prod()=> _commonConfig(
  serviceWsDatabase: FakeServiceWsDatabase(),
  serviceSession: FirebaseServiceSession(googleClientId: Env.googleClientId),
);
```

---

## 🧭 Rutas y Pages

`lib/ui/pages/pages.dart`

```dart
const List<PageModel> pages = <PageModel>[SplashScreenPage.pageModel];
final NavStackModel navStackModel = NavStackModel(pages);

final PageRegistry pageRegistry = PageRegistry.fromDefs(
  <PageDef>[
    PageDef(model: HomePage.pageModel,   builder: (_, __) => const HomePage()),
    PageDef(model: LoginPage.pageModel,  builder: (_, __) => const LoginPage()),
    PageDef(model: SplashScreenPage.pageModel, builder: (_, __) => const SplashScreenPage()),
    // ...otras pages
  ],
  notFoundBuilder: (_, __) => const NotFoundRoutePage(),
  defaultPage: SplashScreenPage.pageModel,
);
```

---

## 🌊 Onboarding (configuración app + auth)

`lib/app/bootstrap/initial_onboarding_steps.dart`

```dart
List<OnboardingStep> buildOnboardingSteps({
  required BlocSession blocSession,
  required AppMode mode,
}) {
  return <OnboardingStep>[
    OnboardingStep(
      title: 'Auth',
      description: 'Verificando sesión previa (silent login)…',
      onEnter: () async => Right<ErrorItem, Unit>(Unit.value),
      autoAdvanceAfter: const Duration(milliseconds: 200),
    ),
    OnboardingStep(
      title: 'Tema',
      description: 'Cargando tema…',
      onEnter: () async => Right<ErrorItem, Unit>(Unit.value),
      autoAdvanceAfter: const Duration(milliseconds: 300),
    ),
    OnboardingStep(
      title: 'Canvas',
      description: 'Preparando canvas…',
      onEnter: () async => Right<ErrorItem, Unit>(Unit.value),
      autoAdvanceAfter: const Duration(milliseconds: 300),
    ),
    OnboardingStep(
      title: 'Inicializando servicios',
      description: 'Iniciando sesión...',
      onEnter: () async {
        // Camino feliz: inicia Google Sign-In (QA/Prod usa Firebase; Dev usa fake)
        blocSession.logInWithGoogle();
        return Right<ErrorItem, Unit>(Unit.value);
      },
      autoAdvanceAfter: const Duration(milliseconds: 300),
    ),
  ];
}
```

---

## 💦 Splash que dispara Onboarding y deja navegar al Sync

`lib/ui/pages/splash_screen_page.dart`

```
final BlocOnboarding onboarding = context.appManager.onboarding;
final BlocSession blocSession = context.appManager.requireModuleByKey(BlocSession.name);

final steps = buildOnboardingSteps(blocSession: blocSession, mode: Env.mode);

WidgetsBinding.instance.addPostFrameCallback((_) {
  if (onboarding.state.status == OnboardingStatus.idle) {
    onboarding.configure(steps);
    onboarding.start();
  }
  if (onboarding.state.status == OnboardingStatus.completed ||
      onboarding.state.status == OnboardingStatus.skipped) {
    // Por compatibilidad; el AuthNavigatorSync también re-enrutará
    context.appManager.replaceTopModel(HomePage.pageModel);
  }
});
```

---

## 🔐 Login Page (botón Google)

`lib/ui/pages/session/login_page.dart`

```
final BlocSession bloc = context.appManager.requireModuleByKey(BlocSession.name);

return StreamBuilder<SessionState>(
  stream: bloc.sessionStream,
  builder: (_, __) {
    if (bloc.state is Authenticating) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [CircularProgressIndicator(), InlineTextWidget('Verificando Auth')],
      );
    }
    return ElevatedButton(
      onPressed: () async {
        final Either<ErrorItem, UserModel> result = await bloc.logInWithGoogle();
        result.fold(
          (err) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.description))),
          (_)   => context.appManager.pageManager.pushDistinctTop(HomePage.pageModel),
        );
      },
      child: const Text('Continuar con Google'),
    );
  },
);
```

---

## 💻 FirebaseServiceSession (QA/Prod)

* Respeta el **shape** del fake (`Map<String,dynamic>` con `jwt.accessToken/issuedAt/expiresAt`).
* Usa `google_sign_in` (API `initialize` + `authenticate`).
* Debounce de `authStateChanges()`.

> Ya integrado en `lib/data/services/firebase_service_session.dart` (no repetir aquí por brevedad).

---

## ▶️ Comandos (por ambiente)

**Web (QA)**

```bash
flutter run -d chrome \
  --dart-define=APP_MODE=qa \
  --dart-define=FIREBASE_ENV=qa \
  --dart-define=GOOGLE_CLIENT_ID=TU_WEB_CLIENT_ID.apps.googleusercontent.com
```

**Android (Prod)**

```bash
flutter run -d android \
  --dart-define=APP_MODE=prod \
  --dart-define=FIREBASE_ENV=prod
# Asegura google-services.json + SHA-1/256 en Firebase Console
```

**Windows (QA)**

```bash
flutter build windows \
  --dart-define=APP_MODE=qa \
  --dart-define=FIREBASE_ENV=qa \
  --dart-define=GOOGLE_CLIENT_ID=TU_WEB_CLIENT_ID.apps.googleusercontent.com
```

---

## 🧪 Checklist (Camino feliz)

* [ ] Onboarding corre y muestra pasos.
* [ ] En QA/Prod, `Firebase.initializeApp` ocurrió (Dev no).
* [ ] Botón **Continuar con Google** → popup → regresa a app autenticada.
* [ ] `BlocSession.isAuthenticated == true` tras login.
* [ ] **AuthNavigatorSync** te envía a **Home**; al cerrar sesión (`Home → Cerrar sesión`), vuelve a **Login**.
* [ ] Refresh de token no parpadea (debounce activo en stream).

---

## 🛠 Troubleshooting rápido

* **Web/Windows**: si no aparece popup, valida `GOOGLE_CLIENT_ID` y dominios autorizados (incluye `localhost`).
* **Android**: error de credenciales → revisa `SHA-1/256` y `google-services.json`.
* **No navega**: confirma que `BlocSession` está en `blocModuleList` y que se instaló `_installAuthNavigatorSync`.

---

## 🔒 Notas de seguridad

* El **ID Token** se guarda sólo en memoria de la app (en `jwt`).
* Para backend calls, usa el `jwt.accessToken` (y renueva vía `refreshSession` cuando corresponda).
* No loguear tokens ni PII en producción.
