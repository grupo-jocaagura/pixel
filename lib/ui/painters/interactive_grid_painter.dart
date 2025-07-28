import 'package:flutter/material.dart';

import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';

class InteractiveGridPainter extends CustomPainter {
  InteractiveGridPainter({required this.modelCanvas, this.gridLineColor});

  final ModelCanvas modelCanvas;
  final Color? gridLineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double cellSize = size.width / modelCanvas.width;
    final int cellsInColumn = (size.height / cellSize).ceil();

    final Paint borderPaint = Paint()
      ..color = gridLineColor ?? Colors.transparent
      ..strokeWidth = 1;

    // Rellenar celdas activas
    for (final ModelPixel pixel in modelCanvas.pixels.values) {
      final int x = pixel.x;
      final int y = pixel.y;

      final Paint fillPaint = Paint()
        ..color = Color(
          int.parse(pixel.hexColor.replaceFirst('#', ''), radix: 16),
        )
        ..style = PaintingStyle.fill;

      final Rect rect = Rect.fromLTWH(
        x * cellSize,
        y * cellSize,
        cellSize,
        cellSize,
      );
      canvas.drawRect(rect, fillPaint);
    }

    // Dibujar grilla
    for (int i = 0; i <= modelCanvas.width; i++) {
      final double dx = i * cellSize;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), borderPaint);
    }
    for (int j = 0; j <= cellsInColumn; j++) {
      final double dy = j * cellSize;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
