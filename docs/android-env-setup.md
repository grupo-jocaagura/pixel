# Pixel — Guía de Configuración de Ambientes Android (Dev / QA / Prod)

**Última actualización:** 2025-10-02 02:37

Esta guía documenta el *camino feliz* que seguimos para dejar listos los ambientes Android de **Pixel al Movimiento** con **flavors**, **Firebase (QA/PROD)**, **firma de release** y **builds**. Está pensada para repetir el proceso sin tropiezos.

> Proyecto base y convenciones: ver la guía de estructura `jocaagura_domain` usada por el repo de Pixel.

---

## 0) Nombres y convenciones

- **ApplicationId base (prod):** `com.jocaagura.pixel`
- **Flavors:** `dev`, `qa`, `prod`
    - `dev` → `applicationId = com.jocaagura.pixel.dev`
    - `qa`  → `applicationId = com.jocaagura.pixel.qa`
    - `prod`→ `applicationId = com.jocaagura.pixel`
- **Namespace Android:** `com.jocaagura.pixel`
- **Firebase proyectos:**
    - QA  → `pixel-qa` (Project ID p.ej. `pixel-qa-9c8b6`)
    - PROD→ `pixel-prod` (Project ID p.ej. `pixel-prod-1b8ce`)

---

## 1) Keystore de producción (upload key)

Generar **una sola** upload key para Pixel (Windows, PowerShell):

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkeypair -v `
  -keystore "C:\firmas\pixel\pixel_release.jks" `
  -alias pixel -keyalg RSA -keysize 2048 -validity 36500
```

Ver huellas para Firebase (SHA-1 / SHA-256):

```powershell
& "$env:JAVA_HOME\bin\keytool.exe" -list -v `
  -keystore "C:\firmas\pixel\pixel_release.jks" -alias pixel
```

**No comitear** el `.jks`. Guardarlo en un vault seguro.

---

## 2) `key.properties`

Crear `android/app/key.properties` (no comitear si contiene secretos):

```
storeFile=C:\firmas\pixel\pixel_release.jks
storePassword=TU_STORE_PASSWORD
keyAlias=pixel
keyPassword=TU_KEY_PASSWORD
```

Agregar `android/app/key.properties` a `.gitignore` si guarda secretos.

---

## 3) Gradle (Kotlin DSL) — flavors + firma

Archivo: `android/app/build.gradle.kts`

Puntos clave:
- `namespace = "com.jocaagura.pixel"`
- `defaultConfig.applicationId = "com.jocaagura.pixel"`
- **Flavors** con `applicationIdSuffix` (no usar suffix en `buildTypes`).
- Firma `release` con `key.properties`.
- Java 17 alineado (si toolchain lo soporta).

Bloque de referencia (resumen):

```kotlin
android {
    namespace = "com.jocaagura.pixel"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_17.toString() }

    defaultConfig {
        applicationId = "com.jocaagura.pixel"
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion

        val vc = project.findProperty("VERSION_CODE")?.toString()?.toInt() ?: flutter.versionCode
        val vn = project.findProperty("VERSION_NAME")?.toString() ?: flutter.versionName
        versionCode = vc
        versionName = vn
    }

    signingConfigs {
        create("release") {
            val kp = java.util.Properties().apply {
                val f = file("key.properties")
                if (f.exists()) load(java.io.FileInputStream(f))
            }
            if (kp.isNotEmpty()) {
                storeFile = file(kp.getProperty("storeFile"))
                storePassword = kp.getProperty("storePassword")
                keyAlias = kp.getProperty("keyAlias")
                keyPassword = kp.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        getByName("debug") { isDebuggable = true }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev")  {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Pixel (DEV)")
        }
        create("qa")   {
            dimension = "env"
            applicationIdSuffix = ".qa"
            versionNameSuffix = "-qa"
            resValue("string", "app_name", "Pixel (QA)")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Pixel")
        }
    }
}
```

Plugins requeridos en el mismo archivo:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}
```

---

## 4) Firebase — apps y `google-services.json` por flavor

En **pixel-qa** crea app Android **`com.jocaagura.pixel.qa`**.  
En **pixel-prod** crea app Android **`com.jocaagura.pixel`**.

En **cada app** agrega huellas de la **upload key**:
- SHA-1: `F2:40:D1:57:34:8A:0E:89:02:BF:03:F0:3E:33:C0:41:8C:25:10:CF`
- SHA-256: `AE:96:B1:EE:30:E3:AC:BC:B8:B0:8D:01:E4:76:AC:89:33:99:DF:BF:8F:F3:C2:14:60:98:A3:1B:54:28:27:A2`

Descarga y coloca los JSON **solo** aquí:
```
android/app/src/qa/google-services.json   // debe tener "package_name": "com.jocaagura.pixel.qa"
android/app/src/prod/google-services.json // debe tener "package_name": "com.jocaagura.pixel"
```

> **No** dejes un `google-services.json` en `android/app/` ni en `android/app/src/main/` para evitar conflictos con flavors.

---

## 5) `firebase_options_*.dart`

Desde la **raíz** del proyecto (donde está `pubspec.yaml`), usando los **Project ID exactos**:

```powershell
# QA
flutterfire configure `
  --project=pixel-qa-9c8b6 `
  --android-package-name com.jocaagura.pixel.qa `
  --platforms=android `
  --out=lib/firebase_options_qa.dart `
  --yes

# PROD
flutterfire configure `
  --project=pixel-prod-1b8ce `
  --android-package-name com.jocaagura.pixel `
  --platforms=android `
  --out=lib/firebase_options_prod.dart `
  --yes
```

> Estos archivos **sí se comitean**. Contienen IDs públicos de cliente.

---

## 6) Código Flutter (selección de ambiente)

`lib/main.dart` (extracto):

```dart
void main() async {
  await initFirebaseIfNeeded();        // inicializa según Env.mode (qa/prod)
  final AppConfig appCfg = pixelConfig.byMode(Env.mode);
  runApp(JocaaguraApp(appManager: AppManager(appCfg), /* ... */));
}
```

`lib/app/env.dart` lee `--dart-define` (p. ej. `APP_MODE` y `FIREBASE_ENV`).  
`pixelConfig.byMode(AppMode)` permite escoger `dev/qa/prod` (por ahora mapea a `dev()` hasta que prod/qa tengan servicios propios).

---

## 7) Builds (PowerShell, una sola línea)

**QA (APK debug):**
```powershell
cd "C:\flutter apps\pixel"; flutter build apk --flavor qa --debug --dart-define=APP_MODE=qa --dart-define=FIREBASE_ENV=qa
```

**PROD (AAB release firmado):**
```powershell
cd "C:\flutter apps\pixel"; flutter build appbundle --flavor prod --release --dart-define=APP_MODE=prod --dart-define=FIREBASE_ENV=prod
```

**Opcional (limpieza previa):**
```powershell
cd "C:\flutter apps\pixel"; flutter clean; flutter pub get
```

---

## 8) Verificaciones útiles

**Reporte de firma (QA/PROD):**
```powershell
cd "C:\flutter apps\pixel\android"; .\gradlew signingReport
```
Revisa que `qaRelease` y `prodRelease` usen:
- Store: `C:\firmas\pixel\pixel_release.jks`
- Alias: `pixel`
- SHA-1/256 iguales a los registrados en Firebase.

**Diagnóstico del plugin de Google Services:**
```powershell
cd "C:\flutter apps\pixel\android"
.\gradlew :app:processQaDebugGoogleServices --info --stacktrace
.\gradlew :app:processProdReleaseGoogleServices --info --stacktrace
```

---

## 9) Problemas comunes (y soluciones)

- **`No matching client found for package name ...`**  
  El `google-services.json` del flavor **no** coincide con el `applicationId` efectivo **o** está en carpeta equivocada.  
  → Verifica ruta y `"package_name"` dentro del JSON. Elimina cualquier JSON en `app/` o `src/main/`.

- **El FlutterFire CLI quiere crear apps nuevas**  
  → Usa el **Project ID exacto** (`pixel-qa-9c8b6`, `pixel-prod-1b8ce`) o alias de `firebase use --add`. Ejecuta desde la **raíz** del proyecto, no desde `android/`.

- **`keytool` no se reconoce**  
  → Define `JAVA_HOME` a `…\Android Studio\jbr` y agrega `…\jbr\bin` al PATH, o ejecuta el `keytool.exe` con ruta completa.

- **Tras publicar en Play**  
  → Agrega también el **App Signing SHA-1** de Play en Firebase (además del de la upload key).

---

## 10) Qué se comitea / qué no

**Comitear:**
- `lib/firebase_options_qa.dart`
- `lib/firebase_options_prod.dart`
- `android/app/src/qa/google-services.json` (opcional pero facilita CI)
- `android/app/src/prod/google-services.json` (opcional pero facilita CI)

**No comitear:**
- `android/app/key.properties`
- `*.jks` (keystores)

---

## 11) Mini-checklist final

- [ ] `build.gradle.kts` con flavors (dev/qa/prod) y firma release.
- [ ] `applicationId` base `com.jocaagura.pixel` + `namespace` alineado.
- [ ] `google-services.json` por flavor **en la carpeta del flavor** con `package_name` correcto.
- [ ] `firebase_options_qa.dart` y `firebase_options_prod.dart` presentes.
- [ ] Huellas SHA-1/256 de upload key en **ambas** apps de Firebase.
- [ ] Builds QA (APK debug) y PROD (AAB release) **exitosos**.
- [ ] (Cuando toque) agregar App Signing SHA-1 de Play a Firebase.

---

**Contacto rápido:** si algo falla, ejecutar los comandos de diagnóstico de Google Services y revisar las rutas/IDs. Con esta guía, replicar ambientes Android en Pixel debería tomar minutos.
