# CHANGELOG Pixarra app

This document follows the guidelines of [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-09-16

### added
- **Github** Configuracion inicial del repositorio en github
- **Readme** Actualizacion del readme y politicas de uso
- **License** Actualizacion de la licencia

## [0.0.2] - 2025-10-10

### added
- **Web/Firebase Hosting**: Configuración de Firebase para **QA/Prod** en web y guía de despliegue (`docs/web-env-setup.md`).
- **Android flavors**: `dev`, `qa`, `prod` con `applicationIdSuffix`, firma por `key.properties`, Java 17 y `google-services.json` por sabor.
- **Inicialización de Firebase**: Bootstrap condicional por ambiente (QA/Prod) y `main.dart` asíncrono.
- **Autenticación Google**: `FirebaseServiceSession`, `LoginPage`, navegación reactiva (`AuthNavigatorSync`), botón **Sign out**, y soporte **multiplataforma** (Web/Android/iOS/Windows/macOS/Linux).
- **Google Sheets como DB**: `GoogleSheetsCanvasDb` con CRUD de canvas; integración **Drive API** para ubicar/crear hojas; streams (`collectionStream`/`documentStream`) y caché en memoria.
- **Rendimiento**: Persistencia de `spreadsheetId` con `shared_preferences` y abstracción `ServiceSharedPreferences`.
- **Documentación**: Guías de autenticación (`firebase-auth-setup.md`) y de Android (`docs/android-env-setup.md`).

### changed
- **PixelConfig**: Soporte por ambiente (`dev/qa/prod`) e inyección de servicios; `FIREBASE_ENV` por defecto pasa de `prod` a `dev`.
- **Auth Web**: Fallback automático a `signInWithRedirect` cuando el popup es bloqueado; manejo de `processRedirectResultOnce()` al iniciar; scopes de Sheets/Drive unificados.
- **App shell**: `HomePage` envuelta en `StreamBuilder` según `SessionState`; `firebase_bootstrap.dart` más robusto.
- **Sheets**: Eliminado `SheetsClientFactory`; cliente autenticado integrado en `GoogleSheetsCanvasDb`; **debounce** de escrituras y de actualizaciones de UI; **polling** en segundo plano para sincronización bidireccional.

### fixed
- **Reinicialización Firebase**: Evita reinit involuntario.
- **Sheets vacías**: Manejo seguro de hojas remotas sin datos.
- **Concurrencia de token**: `CoalescedTokenProvider` y `_sheetsTokenInFlight` para impedir múltiples popups y compartir el mismo `Future`.

### removed
- **Web/Logs**: `debugPrint` obsoletos.
- **Git ignore**: Regla que ignoraba `google-services.json` (ahora se versionan por sabor).