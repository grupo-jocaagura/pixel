# Pixel — Guía Web (QA/Prod) con Firebase Hosting

**Última actualización:** 2025-10-02 19:52

Esta guía deja listo el flujo Web para **Pixel al Movimiento** con QA/Prod: credenciales via FlutterFire, builds y deploy a Firebase Hosting. Incluye comandos que funcionaron en tu entorno (sin `--web-renderer` en `flutter run`).

---

## 0) Pre-requisitos

- Node.js + Firebase CLI: `npm i -g firebase-tools`
- Flutter con soporte Web: `flutter config --enable-web`
- FlutterFire CLI: `dart pub global activate flutterfire_cli`
- Acceso a los proyectos:
  - QA → **Project ID:** `pixel-qa-9c8b6`
  - PROD → **Project ID:** `pixel-prod-1b8ce`

---

## 1) Login limpio y verificación

> Ejecutar desde la **raíz** del repo (donde está `pubspec.yaml`).

```powershell
dart pub global activate flutterfire_cli; firebase logout; firebase login
firebase login:list
firebase projects:list
```

Opcional (recomendado): alias locales.
```powershell
firebase use --add
# alias qa  -> pixel-qa-9c8b6
# alias prod-> pixel-prod-1b8ce
```

---

## 2) Credenciales Web con FlutterFire

Genera/actualiza los `firebase_options_*.dart` con la sección **Web**:

```powershell
# QA
flutterfire configure --project=pixel-qa-9c8b6 --platforms=web --out=lib/firebase_options_qa.dart --yes

# PROD
flutterfire configure --project=pixel-prod-1b8ce --platforms=web --out=lib/firebase_options_prod.dart --yes
```

**Verifica** que ambos archivos incluyan claves Web (`apiKey`, `authDomain`, etc.).

---

## 3) `firebase.json` y `.firebaserc` con targets

**`.firebaserc`**
```json
{
  "projects": {
    "qa": "pixel-qa-9c8b6",
    "prod": "pixel-prod-1b8ce"
  }
}
```

**`firebase.json`** (dos sitios, SPA y cache de estáticos)
```json
{
  "hosting": [
    {
      "target": "web-qa",
      "public": "build/web_qa",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [{ "source": "**", "destination": "/index.html" }],
      "headers": [{ "source": "**/*.@(js|css|wasm)", "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }] }]
    },
    {
      "target": "web-prod",
      "public": "build/web_prod",
      "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
      "rewrites": [{ "source": "**", "destination": "/index.html" }],
      "headers": [{ "source": "**/*.@(js|css|wasm)", "headers": [{ "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }] }]
    }
  ]
}
```

**Aplica targets al site del proyecto** (siteId suele ser el Project ID):
```powershell
firebase hosting:sites:list --project pixel-qa-9c8b6
firebase target:apply hosting web-qa  pixel-qa-9c8b6  --project pixel-qa-9c8b6

firebase hosting:sites:list --project pixel-prod-1b8ce
firebase target:apply hosting web-prod pixel-prod-1b8ce --project pixel-prod-1b8ce
```

---

## 4) Ejecutar la app Web (QA/Prod) — comandos verificados

**QA (Chrome local):**
```powershell
cd "C:\flutter apps\pixel"; flutter run -d chrome --dart-define=APP_MODE=qa --dart-define=FIREBASE_ENV=qa
```

**PROD (Chrome local):**
```powershell
cd "C:\flutter apps\pixel"; flutter run -d chrome --dart-define=APP_MODE=prod --dart-define=FIREBASE_ENV=prod
```

> Si deseas forzar CanvasKit en `run`, prueba `--web-renderer=canvaskit`. Si el flag no existe en tu versión, omítelo (como arriba).

---

## 5) Builds Web por ambiente

**QA (salida: `build/web_qa`)**
```powershell
cd "C:\flutter apps\pixel"; flutter build web --release -o build/web_qa --dart-define=APP_MODE=qa --dart-define=FIREBASE_ENV=qa
```

**PROD (salida: `build/web_prod`)**
```powershell
cd "C:\flutter apps\pixel"; flutter build web --release -o build/web_prod --dart-define=APP_MODE=prod --dart-define=FIREBASE_ENV=prod
```

*(Opcional)* Para PWA y CanvasKit:
```powershell
# Añade cuando tu CLI soporte los flags
# --pwa-strategy=offline-first --web-renderer=canvaskit
```

---

## 6) Deploy a Firebase Hosting

**QA**
```powershell
firebase deploy --only hosting:web-qa --project pixel-qa-9c8b6
```

**PROD**
```powershell
firebase deploy --only hosting:web-prod --project pixel-prod-1b8ce
```

**Preview por PR (opcional, 7 días):**
```powershell
firebase hosting:channel:deploy pr-123 --only hosting:web-prod --project pixel-prod-1b8ce --expires 7d
```

---

## 7) Dominio personalizado

- Prod: `pixel.jocaagura.com` (opcional QA: `qa.pixel.jocaagura.com`).
- En Hosting → **Add custom domain** y sigue los registros DNS que indique.
- Una vez verificado, el dominio servirá el site de Producción.

> Para **Dynamic Links** sugerimos un subdominio separado (p. ej. `go.pixel.jocaagura.com`).

---

## 8) Troubleshooting rápido

- **FlutterFire CLI “Found 0 projects” / Timeout**  
  ```powershell
  dart pub global activate flutterfire_cli; firebase logout; firebase login
  firebase projects:list
  ```
  Reintenta desde la **raíz** y usando **Project ID** exacto.

- **Deploy al sitio equivocado**  
  Verifica `firebase target:apply` o usa siempre `--project` y `--only hosting:<target>`.

- **El bundle apunta al proyecto incorrecto**  
  Revisa `--dart-define` y que `firebase_options_*.dart` tenga la sección Web correcta.

---

## 9) Qué comitear

- ✔️ `firebase.json`, `.firebaserc`
- ✔️ `lib/firebase_options_qa.dart`, `lib/firebase_options_prod.dart`
- ❌ No subir service accounts privadas (no se necesitan para Hosting).

---

## 10) Checklist final

- [ ] `firebase_options_qa.dart` / `firebase_options_prod.dart` con config Web.
- [ ] `firebase.json` con `web-qa` y `web-prod` + rewrites SPA.
- [ ] `.firebaserc` con proyectos y targets aplicados.
- [ ] `flutter run` QA/Prod funcionando en Chrome.
- [ ] Builds en `build/web_qa` y `build/web_prod`.
- [ ] Deploy QA/Prod exitoso.
- [ ] Dominio `pixel.jocaagura.com` apuntando al site de Prod.
