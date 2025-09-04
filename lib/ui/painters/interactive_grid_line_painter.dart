import 'dart:math';

import 'package:flutter/material.dart';

import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../../shared/util_color.dart';

class InteractiveGridLinePainter extends CustomPainter {
  InteractiveGridLinePainter({
    required this.canvas,
    required this.cellPadding,
    this.showCoordinates = false,
    this.coordinateColor,
    this.previewPixels,
    this.origin,
    this.destiny,
  });

  final ModelCanvas canvas;
  final double cellPadding;
  final bool showCoordinates;
  final Color? coordinateColor;
  final Iterable<ModelPixel>? previewPixels;
  final Point<int>? origin;
  final Point<int>? destiny;

  @override
  void paint(Canvas canvasPx, Size size) {
    // 1) Fondo blanco
    canvasPx.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // 2) Métricas de celda
    final double cw = size.width / canvas.width;
    final double ch = size.height / canvas.height;
    Rect cellRect(int x, int y) =>
        Rect.fromLTWH(x * cw, y * ch, cw, ch).deflate(cellPadding);

    // 3) Grilla simple (opcional, si ya la tienes)
    // drawGridLines(canvasPx, cw, ch);

    // 4) Coordenadas de celda (costo O(W*H); deja toggleable)
    if (showCoordinates) {
      final Color textColor = coordinateColor ?? Colors.grey;
      final double fs = (cw < ch ? cw : ch) * 0.30; // ~30% del tamaño de celda
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
          final Rect r = cellRect(x, y);
          // texto "x,y"
          tp.text = TextSpan(text: '$x,$y', style: ts);
          tp.layout(maxWidth: r.width);
          final Offset p = Offset(
            r.left + (r.width - tp.width) / 2,
            r.top + (r.height - tp.height) / 2,
          );
          tp.paint(canvasPx, p);
        }
      }
    }

    // 5) Resaltado origen/destino (borde)
    final Paint hi = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = (cw + ch) * 0.05; // grosor relativo
    if (origin != null) {
      canvasPx.drawRect(cellRect(origin!.x, origin!.y), hi);
    }
    if (destiny != null) {
      canvasPx.drawRect(cellRect(destiny!.x, destiny!.y), hi);
    }

    // 6) Preview de línea (si hay)
    if (previewPixels != null) {
      final Paint pv = Paint()
        ..color = (coordinateColor ?? Colors.blue).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      for (final ModelPixel p in previewPixels!) {
        if (p.x >= 0 && p.y >= 0 && p.x < canvas.width && p.y < canvas.height) {
          canvasPx.drawRect(cellRect(p.x, p.y), pv);
        }
      }
    }

    // 7) Píxeles existentes del ModelCanvas
    for (final ModelPixel px in canvas.pixels.values) {
      final Paint pxPaint = Paint()
        ..color = UtilColor.fromHex(px.hexColor)
        ..style = PaintingStyle.fill;
      canvasPx.drawRect(cellRect(px.x, px.y), pxPaint);
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveGridLinePainter old) {
    return old.canvas != canvas ||
        old.coordinateColor != coordinateColor ||
        old.showCoordinates != showCoordinates ||
        old.origin != origin ||
        old.destiny != destiny ||
        old.previewPixels != previewPixels;
  }
}
