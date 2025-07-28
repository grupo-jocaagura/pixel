# Pixel al Movimiento

Aplicación de ejemplo en Flutter que acompaña el taller **"Del Pixel al Movimiento"**. Esta app permite experimentar con el concepto de píxel, resolución y animación en un lienzo interactivo, utilizando `CustomPainter` y otros componentes nativos de Flutter.

---

## 🚀 Características

* **Lienzo de píxeles interactivo**: muestra una grilla configurable de píxeles.
* **Control de resolución**: ajusta filas, columnas y tamaño de cada píxel.
* **Animaciones básicas**: desplaza y rota la grilla automáticamente.
* **Parámetros en tiempo real**: modifica colores, velocidad y patrones de animación.
* **Arquitectura limpia**: estructura modular basada en `models`, `painters`, `widgets` y `utils`.

---

## 🛠 Requisitos

* Flutter >= 3.0.0
* Dart >= 2.18.0
* Dispositivo o emulador Android/iOS configurado

---

## ⚙️ Instalación

1. Clona este repositorio:

   ```bash
   git clone https://github.com/tu-usuario/pixel-al-movimiento.git
   ```
2. Entra al directorio del proyecto:

   ```bash
   cd pixel-al-movimiento
   ```
3. Obtén las dependencias:

   ```bash
   flutter pub get
   ```

---

## ▶️ Ejecución

Para ejecutar la aplicación en un dispositivo conectado o emulador:

```bash
flutter run
```

Para compilar un APK de producción:

```bash
flutter build apk --release
```

---

## 🗂 Estructura del proyecto

```
lib/
├── main.dart                  # Punto de entrada de la app
├── models/                    # Modelos de datos (ModelPixel, ModelCanvas)
│   ├── model_pixel.dart
│   └── model_canvas.dart
├── painters/                  # Lógica de dibujo en canvas (PixelPainter)
│   └── pixel_painter.dart
├── widgets/                   # Widgets reutilizables (PixelCanvasWidget)
│   └── pixel_canvas_widget.dart
└── utils/                     # Funciones y utilidades comunes
    └── utils.dart
```

---

## 🤝 Contribuir

1. Haz un *fork* de este repositorio.
2. Crea una rama con tu funcionalidad o corrección:

   ```bash
   git checkout -b feature/nueva-funcionalidad
   ```
3. Realiza tus cambios y haz *commit*:

   ```bash
   git commit -m "Añade descripción de tu cambio"
   ```
4. Envía tu ramo y abre un *pull request*.

Agradecemos cualquier mejora y sugerencia para enriquecer el taller.

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
