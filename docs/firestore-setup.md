# Firestore Setup — Pixel (QA/Prod)

**Última actualización:** 2025-10-10  
**Ámbito:** Configurar **Cloud Firestore** para Pixel (QA y Prod), alineado con el flujo `UI → AppManager → Bloc → UseCase → Repository → Gateway → Service`.

> Estructura objetivo en Firestore (por usuario autenticado):  
> `users/{uid}/canvas/{docId}`  
> Inicialmente un único canvas por usuario (p. ej. `default_app_canvas`). Más adelante podemos manejar múltiples `docId` sin romper la interfaz.

---

## 0) Pre-requisitos

- Proyectos Firebase creados:
  - **QA** → Project ID: `pixel-qa-9c8b6`
  - **PROD** → Project ID: `pixel-prod-1b8ce`
- Pixel con FlutterFire configurado para Web (ver `firebase_options_qa.dart` / `firebase_options_prod.dart`).
- Autenticación Firebase habilitada (Google Sign-In).

---

## 1) Crear la base de datos (por proyecto)

1. Entra a **Firebase Console** → selecciona **QA** (repite en **PROD**).
2. Menú izquierdo → **Firestore Database** → **Create database**.
3. **Modo:** *Firestore (Native)*.
4. **Ubicación:** multi-región recomendada (ej. `nam5` si tu público está en Américas).  
   > _Importante_: la ubicación **no** se puede cambiar después.
5. **Reglas:** empieza directamente con reglas de producción (ver §4) o temporalmente “test” durante la prueba inicial (cámbialas antes del release).

---

## 2) Estructura de datos

- Colección raíz multi-tenant: `users`
- Documento por usuario: `{uid}` (UID de `FirebaseAuth`)
- Subcolección de trabajo: `canvas`
- Documento del canvas: `{docId}` (inicial: `default_app_canvas`)

```

users/
{uid}/
canvas/
default_app_canvas   (Map<String, dynamic> — JSON del ModelCanvas)

````

> A futuro (múltiples canvas por usuario) solo agregamos más `docId` en `users/{uid}/canvas/*`.

---

## 3) Inicialización en la app

Asegúrate de inicializar Firebase **antes** de usar Firestore y de que la app seleccione las opciones correctas según el flavor (QA/Prod):

```dart
// main.dart (simplificado)
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options_qa.dart' as qa;
import 'firebase_options_prod.dart' as prod;

Future<void> bootstrapFirebase({required bool isProd}) async {
  await Firebase.initializeApp(
    options: isProd
        ? prod.DefaultFirebaseOptions.currentPlatform
        : qa.DefaultFirebaseOptions.currentPlatform,
  );

  // (Opcional) Persistencia offline
  // FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
}
````

---

## 4) Reglas de seguridad (QA/Prod)

Restringen acceso a **solo el propietario** del documento (`uid`):

```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Aísla datos por usuario: users/{uid}/...
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### (Opcional futuro) Lectura pública del canvas

Si en el futuro permitimos ver canvases de otros usuarios (solo lectura):

```txt
match /users/{userId}/canvas/{docId} {
  // Lectura pública
  allow get: if true;
  // Escritura solo del dueño
  allow create, update, delete: if request.auth != null && request.auth.uid == userId;
}
```

> **Publica** las reglas en cada proyecto (QA/Prod) desde la consola o CLI antes del release.

---

## 5) Servicio y Gateway (integración)

El **ServiceFirebaseWsDatabase** mapea automáticamente `collection: 'canvas'` a `users/{uid}/canvas` (obtiene `uid` de `FirebaseAuth`).
Tu **GatewayCanvasImpl** permanece igual:

```
final ServiceWsDatabase<Map<String, dynamic>> db = ServiceFirebaseWsDatabase(
  config: const WsDbConfig(
    emitInitial: true,
    deepCopies: true,
    dedupeByContent: true,
    orderCollectionsByKey: true,
  ),
  streamErrorsAsErrorItemJson: true, // errores como ErrorItem JSON en streams
);

final GatewayCanvas gw = GatewayCanvasImpl(db);

// Seed (si no existe) y lectura
await gw.write(defaultModelCanvasId, defaultModelCanvas.toJson());
final either = await gw.read(defaultModelCanvasId);

// Watch (reactivo)
gw.watch(defaultModelCanvasId).listen((either) {
  either.fold(
    (err) => /* manejar ErrorItem */ {},
    (json) => /* renderizar canvas */ {},
  );
});
```

---

## 6) Smoke test (QA y Prod)

1. Inicia sesión con Google (FirebaseAuth).
2. Llama a:

    * `gw.write(defaultModelCanvasId, defaultModelCanvas.toJson())`
    * `gw.read(defaultModelCanvasId)` → debe devolver `Right(Map)`
    * `gw.watch(defaultModelCanvasId)` → debe emitir cambios al pintar.
3. Verifica en Firestore Console que aparezca:

   ```
   users/{uid}/canvas/default_app_canvas
   ```

**Errores frecuentes:**

* `permission-denied` → usuario no autenticado o reglas no publicadas.
* `not-found` (en lectura directa) → el doc aún no existe; crea con `write` o maneja `{}` si lees vía stream.
* Proyecto equivocado → revisa `firebase_options_*.dart` y `--dart-define` del build.

---

## 7) Ambientes: QA vs Prod (no pisar)

* Mantén proyectos separados (recomendado):
  `.firebaserc`

  ```json
  {
    "projects": {
      "qa":   "pixel-qa-9c8b6",
      "prod": "pixel-prod-1b8ce"
    }
  }
  ```
* A nivel de **Hosting**, usa `targets` distintos (p. ej. `web-qa` y `web-prod`) y publica cada build en su site correspondiente.
* A nivel de **Firestore**, no hay “targets”: cada **proyecto** tiene su propia base de datos (no se pisan entre sí).

---

## 8) (Opcional) Emulador local

Para desarrollo aislado:

```bash
firebase emulators:start --only firestore
```

Configura la app para apuntar al emulador cuando `APP_MODE=dev`:

```
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
```

---

## 9) Checklist final

* [ ] Firestore creado en **QA** y **PROD** (ubicación correcta).
* [ ] **Reglas** publicadas y probadas (solo dueño accede).
* [ ] `firebase_options_qa.dart` / `firebase_options_prod.dart` con sección **Web** completa.
* [ ] Inicialización Firebase por ambiente (QA/Prod) funcionando.
* [ ] `ServiceFirebaseWsDatabase` conectado y `GatewayCanvasImpl` operando.
* [ ] Seed + lectura + stream verificados (documento aparece en consola).
* [ ] Deploy Web (QA/Prod) funcionando con OAuth (origins/redirects configurados).

---

## 10) Qué comitear

* ✔️ `firestore.rules` (si lo gestionas por archivo)
* ✔️ Código de inicialización y servicio (`ServiceFirebaseWsDatabase`)
* ✔️ `firebase_options_qa.dart`, `firebase_options_prod.dart`
* ❌ No comitear credenciales de servicio (no se requieren para Hosting/Firestore cliente).
