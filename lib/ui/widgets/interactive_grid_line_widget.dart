// lib/ui/widgets/interactive_grid_line_widget.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../painters/interactive_grid_line_painter.dart';

/// Strategy to size the grid inside its viewport.
enum GridFit { contain, width, height }

/// Renders the line grid painter in a scrollable container when needed,
/// enforcing a minimum cell size so pixels never become too small.
///
/// If the computed grid (cols*cell, rows*cell) is larger than the viewport,
/// the widget shows horizontal+vertical scrollbars automatically.
class InteractiveGridLineWidget extends StatelessWidget {
  const InteractiveGridLineWidget({
    required this.blocCanvas,
    required this.showCoordinates,
    required this.coordinateColor,
    required this.onCellTap,
    super.key,
    this.origin,
    this.destiny,
    this.previewPixels,
    this.fit = GridFit.contain,
    this.minCellDp = 24.0,
  });

  final BlocCanvas blocCanvas;
  final bool showCoordinates;
  final Color coordinateColor;
  final Point<int>? origin;
  final Point<int>? destiny;
  final Iterable<ModelPixel>? previewPixels;

  /// How to size the grid relative to the viewport.
  final GridFit fit;

  /// Minimum logical pixel size per cell (dp). Typical good value: 20–28.
  final double minCellDp;

  /// Called with (x,y) when user taps a cell.
  final ValueChanged<Point<int>> onCellTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ModelCanvas>(
      stream: blocCanvas.canvasStream,
      initialData: blocCanvas.canvas,
      builder: (_, AsyncSnapshot<ModelCanvas> snap) {
        final ModelCanvas c = snap.data ?? blocCanvas.canvas;

        return LayoutBuilder(
          builder: (_, BoxConstraints constraints) {
            final Size vp = Size(constraints.maxWidth, constraints.maxHeight);

            // Base cell by fit strategy
            final double byW = vp.width / c.width;
            final double byH = vp.height / c.height;
            double base;
            switch (fit) {
              case GridFit.width:
                base = byW;
                break;
              case GridFit.height:
                base = byH;
                break;
              case GridFit.contain:
                base = byW < byH ? byW : byH;
                break;
            }

            // Enforce minimum cell size (logical dp).

            final double cell = base < minCellDp ? minCellDp : base;
            final Size gridSize = Size(cell * c.width, cell * c.height);

            // Painter child, sized to the exact grid size.
            Widget paintChild = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails d) {
                final Offset p = d.localPosition;
                final int x = (p.dx / cell).floor();
                final int y = (p.dy / cell).floor();
                if (x >= 0 && y >= 0 && x < c.width && y < c.height) {
                  onCellTap(Point<int>(x, y));
                }
              },
              child: CustomPaint(
                size: gridSize,
                painter: InteractiveGridLinePainter(
                  canvas: c,
                  cellPadding: 0.25,
                  showCoordinates: showCoordinates,
                  showGrid: blocCanvas.isOn,
                  coordinateColor: coordinateColor,
                  origin: origin,
                  destiny: destiny,
                  previewPixels: previewPixels,
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                ),
              ),
            );

            final bool needsH = gridSize.width > vp.width;
            final bool needsV = gridSize.height > vp.height;

            if (needsH || needsV) {
              // Scroll en ambos ejes cuando el grid excede el viewport.
              paintChild = Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Scrollbar(
                    thumbVisibility: true,
                    notificationPredicate: (ScrollNotification n) =>
                        n.depth == 1,
                    child: SingleChildScrollView(child: paintChild),
                  ),
                ),
              );
              return paintChild;
            }

            // Si cabe, centrar para estética.
            return Center(child: paintChild);
          },
        );
      },
    );
  }
}
