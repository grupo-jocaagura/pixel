// lib/ui/painters/interactive_grid_line_painter.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../app/utils/model_vector_bridge.dart';
import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../../shared/util_color.dart';

/// Paints a pixel-art canvas with optional coordinates, origin/destiny highlight
/// and a preview line. Grid squares are always **square** and the grid is
/// letterboxed and centered in the available area.
///
/// Coordinates (x,y) are drawn inside each cell only when [showCoordinates] is
/// true (O(W*H), use with care on large grids).
class InteractiveGridLinePainter extends CustomPainter {
  InteractiveGridLinePainter({
    required this.canvas,
    this.cellPadding = 0.0,
    this.showCoordinates = false,
    this.showGrid = false,
    this.coordinateColor,
    this.previewPixels,
    this.origin,
    this.destiny,
    this.devicePixelRatio,
  });

  final ModelCanvas canvas;
  final double cellPadding;
  final bool showCoordinates;
  final bool showGrid;
  final Color? coordinateColor;
  final Iterable<ModelPixel>? previewPixels;
  final ModelVector? origin;
  final ModelVector? destiny;

  /// Optional DPR to snap grid lines to physical pixels.
  final double? devicePixelRatio;

  // ---- Layout helpers -------------------------------------------------------

  double _snap(double logical) {
    final double dpr = devicePixelRatio ?? 1.0;
    return (logical * dpr).roundToDouble() / dpr;
  }

  /// Compute square cell size and grid offsets to center the grid.
  ///
  /// Returns (cellSize, offsetX, offsetY, gridWidth, gridHeight).
  (double, double, double, double, double) _gridMetrics(Size size) {
    final int cols = canvas.width;
    final int rows = canvas.height;
    final double cell = min(size.width / cols, size.height / rows);
    final double gridW = cell * cols;
    final double gridH = cell * rows;
    final double ox = (size.width - gridW) / 2;
    final double oy = (size.height - gridH) / 2;
    return (cell, ox, oy, gridW, gridH);
  }

  Rect _cellRect(int x, int y, double cell, double ox, double oy) {
    return Rect.fromLTWH(
      ox + x * cell,
      oy + y * cell,
      cell,
      cell,
    ).deflate(cellPadding);
  }

  @override
  void paint(Canvas c, Size size) {
    // 1) Fondo blanco
    c.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // 2) Métricas cuadradas y centradas
    final (double cell, double ox, double oy, double gridW, double gridH) =
        _gridMetrics(size);

    final bool canShowText =
        showCoordinates &&
        cell >= 12.0 &&
        canvas.width < 200 &&
        canvas.height < 200;
    // 3) (Opcional) fondo del área de grid (por claridad)
    c.drawRect(
      Rect.fromLTWH(ox, oy, gridW, gridH),
      Paint()..color = Colors.white,
    );

    // 4) Coordenadas por celda
    if (showCoordinates && canShowText) {
      final Color textColor = coordinateColor ?? Colors.grey;
      final double fs = cell * 0.30; // ~30% de la celda
      final TextStyle ts = TextStyle(
        fontSize: fs,
        color: textColor,
        height: 1.0,
      );
      final TextPainter tp = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      for (int y = 0; y < canvas.height; y++) {
        for (int x = 0; x < canvas.width; x++) {
          final Rect r = _cellRect(x, y, cell, ox, oy);
          tp.text = TextSpan(text: '$x,$y', style: ts);
          tp.layout(maxWidth: r.width);
          final Offset p = Offset(
            r.left + (r.width - tp.width) / 2,
            r.top + (r.height - tp.height) / 2,
          );
          tp.paint(c, p);
        }
      }
    }

    // 5) Resaltado origen/destino
    final Paint hi = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, cell * 0.06);
    if (origin != null) {
      c.drawRect(_cellRect(origin!.x, origin!.y, cell, ox, oy), hi);
    }
    if (destiny != null) {
      c.drawRect(_cellRect(destiny!.x, destiny!.y, cell, ox, oy), hi);
    }

    // 6) Preview de línea (si hay)
    if (previewPixels != null) {
      final Paint pv = Paint()
        ..color = (coordinateColor ?? Colors.blue).withValues(alpha: 0.65)
        ..style = PaintingStyle.fill;
      for (final ModelPixel p in previewPixels!) {
        if (p.x >= 0 && p.y >= 0 && p.x < canvas.width && p.y < canvas.height) {
          c.drawRect(_cellRect(p.x, p.y, cell, ox, oy), pv);
        }
      }
    }

    // 7) Píxeles existentes del ModelCanvas
    final Paint pxPaint = Paint()..style = PaintingStyle.fill;
    for (final ModelPixel px in canvas.pixels.values) {
      pxPaint.color = UtilColor.fromHex(px.hexColor);
      c.drawRect(_cellRect(px.x, px.y, cell, ox, oy), pxPaint);
    }

    // 8) Grilla (1px físico)
    if (showGrid && canShowText) {
      const Color gl = Color(0x11000000);
      final double stroke = max(1.0 / (devicePixelRatio ?? 1.0), 0.5);
      final Paint line = Paint()
        ..color = gl
        ..strokeWidth = stroke
        ..isAntiAlias = false;

      // verticales
      for (int i = 0; i <= canvas.width; i++) {
        final double x = _snap(ox + i * cell);
        c.drawLine(Offset(x, oy), Offset(x, oy + gridH), line);
      }
      // horizontales
      for (int j = 0; j <= canvas.height; j++) {
        final double y = _snap(oy + j * cell);
        c.drawLine(Offset(ox, y), Offset(ox + gridW, y), line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveGridLinePainter old) {
    return old.canvas != canvas ||
        old.coordinateColor != coordinateColor ||
        old.showCoordinates != showCoordinates ||
        old.origin != origin ||
        old.destiny != destiny ||
        old.previewPixels != previewPixels ||
        old.devicePixelRatio != devicePixelRatio ||
        old.cellPadding != cellPadding;
  }
}
