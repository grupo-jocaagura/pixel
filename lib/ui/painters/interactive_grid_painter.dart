import 'package:flutter/material.dart';

import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../../shared/util_color.dart';

/// Grid painter con “pixel snapping” para evitar líneas fantasma.
/// - Alinea TODOS los bordes a píxel físico.
/// - Desactiva anti-alias en rellenos y líneas.
/// - Limita la cantidad de líneas de grilla a la densidad real de píxeles.
class InteractiveGridPainter extends CustomPainter {
  InteractiveGridPainter({
    required this.modelCanvas,
    required this.devicePixelRatio,
    this.gridLineColor,
  });

  final ModelCanvas modelCanvas;
  final Color? gridLineColor;
  final double devicePixelRatio;

  // Redondea al píxel físico más cercano
  double _snap(double logical) =>
      (logical * devicePixelRatio).roundToDouble() / devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    // Celdas cuadradas basadas en el ancho (como ya venías manejando)
    final int cols = modelCanvas.width;
    final int rows = modelCanvas.height;
    final double cell = size.width / cols;

    // ---- Relleno de píxeles (sin anti-alias) ----
    final Paint fill = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = false;

    for (final ModelPixel p in modelCanvas.pixels.values) {
      // Bordes alineados a píxel físico
      final double l = _snap(p.x * cell);
      final double t = _snap(p.y * cell);
      final double r = _snap((p.x + 1) * cell);
      final double b = _snap((p.y + 1) * cell);

      fill.color = UtilColor.hexToColor(p.hexColor);
      canvas.drawRect(Rect.fromLTRB(l, t, r, b), fill);
    }

    // ---- Grilla (opcional) ----
    final Color? lineColor = gridLineColor;
    final bool showGrid = lineColor != null && lineColor.a != 0;
    if (!showGrid) {
      return;
    }

    // 1px físico exacto
    final double strokeWidth = 1.0 / devicePixelRatio;
    final Paint linePaint = Paint()
      ..color = lineColor
      ..isAntiAlias = false
      ..strokeWidth = strokeWidth;

    // Limitar cantidad de líneas por densidad del dispositivo
    final int maxLinesX = (size.width * devicePixelRatio).floor();
    final int maxLinesY = (size.height * devicePixelRatio).floor();
    final int totalX = cols + 1;
    final int totalY = rows + 1;
    final int stepX = totalX > maxLinesX ? (totalX / maxLinesX).ceil() : 1;
    final int stepY = totalY > maxLinesY ? (totalY / maxLinesY).ceil() : 1;

    // Verticales
    for (int i = 0; i <= cols; i += stepX) {
      final double x = _snap(i * cell);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    // Horizontales
    for (int j = 0; j <= rows; j += stepY) {
      final double y = _snap(j * cell);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveGridPainter old) {
    // Re-pintar cuando cambie el canvas, el color de la grilla o el DPR
    return old.modelCanvas != modelCanvas ||
        old.gridLineColor != gridLineColor ||
        old.devicePixelRatio != devicePixelRatio;
  }
}
