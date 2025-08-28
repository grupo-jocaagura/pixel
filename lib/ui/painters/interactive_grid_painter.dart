import 'package:flutter/material.dart';

import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';

/// Paints an interactive grid ensuring the number of grid lines
/// never exceeds the screen's physical pixel count.
///
/// This avoids overdraw and improves performance on huge canvases.
///
/// ### Example
/// ```dart
/// CustomPaint(
///   painter: InteractiveGridPainter(
///     modelCanvas: canvas,
///     gridLineColor: Colors.grey.withOpacity(0.2),
///     devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
///   ),
/// )
/// ```
class InteractiveGridPainter extends CustomPainter {
  InteractiveGridPainter({
    required this.modelCanvas,
    required this.devicePixelRatio,
    this.gridLineColor,
  });

  final ModelCanvas modelCanvas;
  final Color? gridLineColor;

  /// Device pixel ratio (pass from widget using MediaQuery.devicePixelRatioOf(context)).
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    // Tamaños lógicos
    final double cellSize = size.width / modelCanvas.width;
    final int logicalCols = modelCanvas.width;
    final int logicalRows = (size.height / cellSize).ceil();

    // Máximo de líneas útiles por eje (en píxeles físicos)
    final int maxLinesX = (size.width * devicePixelRatio).floor();
    final int maxLinesY = (size.height * devicePixelRatio).floor();

    // Total de líneas lógicas a trazar
    final int totalLinesX = logicalCols + 1;
    final int totalLinesY = logicalRows + 1;

    // Paso de submuestreo (>= 1)
    final int stepX = totalLinesX > maxLinesX
        ? (totalLinesX / maxLinesX).ceil()
        : 1;
    final int stepY = totalLinesY > maxLinesY
        ? (totalLinesY / maxLinesY).ceil()
        : 1;

    // Grosor y alineación para nitidez en pantalla física
    final double strokeWidth = 1.0 / devicePixelRatio;
    final double pixelAlign = 0.5 / devicePixelRatio;

    final Paint borderPaint = Paint()
      ..color = gridLineColor ?? Colors.transparent
      ..strokeWidth = strokeWidth;

    // Rellenar celdas activas (asegurando alfa FF)
    for (final ModelPixel pixel in modelCanvas.pixels.values) {
      final int x = pixel.x;
      final int y = pixel.y;

      final int argb = int.parse(
        pixel.hexColor.replaceFirst('#', 'FF'),
        radix: 16,
      );

      final Paint fillPaint = Paint()
        ..color = Color(argb)
        ..style = PaintingStyle.fill;

      final Rect rect = Rect.fromLTWH(
        x * cellSize,
        y * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(rect, fillPaint);
    }

    if (borderPaint.color.a != 0) {
      for (int i = 0; i <= logicalCols; i += stepX) {
        final double dx = (i * cellSize).floorToDouble() + pixelAlign;
        canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), borderPaint);
      }
      for (int j = 0; j <= logicalRows; j += stepY) {
        final double dy = (j * cellSize).floorToDouble() + pixelAlign;
        canvas.drawLine(Offset(0, dy), Offset(size.width, dy), borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveGridPainter old) {
    return old.modelCanvas != modelCanvas ||
        old.gridLineColor != gridLineColor ||
        old.devicePixelRatio != devicePixelRatio;
  }
}
