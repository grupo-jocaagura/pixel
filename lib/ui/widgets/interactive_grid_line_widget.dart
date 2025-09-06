import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../app/utils/model_vector_bridge.dart';
import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../painters/interactive_grid_line_painter.dart';

enum GridFit { contain, width, height }

class InteractiveGridLineWidget extends StatefulWidget {
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
  final ModelVector? origin;
  final ModelVector? destiny;
  final Iterable<ModelPixel>? previewPixels;
  final GridFit fit;
  final double minCellDp;
  final ValueChanged<ModelVector> onCellTap;

  @override
  State<InteractiveGridLineWidget> createState() =>
      _InteractiveGridLineWidgetState();
}

class _InteractiveGridLineWidgetState extends State<InteractiveGridLineWidget> {
  final ScrollController _hCtrl = ScrollController();
  final ScrollController _vCtrl = ScrollController();

  @override
  void dispose() {
    _hCtrl.dispose();
    _vCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ModelCanvas>(
      stream: widget.blocCanvas.canvasStream,
      initialData: widget.blocCanvas.canvas,
      builder: (_, AsyncSnapshot<ModelCanvas> snap) {
        final ModelCanvas c = snap.data ?? widget.blocCanvas.canvas;

        return LayoutBuilder(
          builder: (_, BoxConstraints constraints) {
            final Size vp = Size(constraints.maxWidth, constraints.maxHeight);

            // Tamaño base de celda por estrategia
            final double byW = vp.width / c.width;
            final double byH = vp.height / c.height;
            double base;
            switch (widget.fit) {
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

            // Enforce mínimo por celda
            final double cell = base < widget.minCellDp
                ? widget.minCellDp
                : base;
            final Size gridSize = Size(cell * c.width, cell * c.height);

            // Contenido pintado al tamaño real del grid
            Widget content = GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails d) {
                final Offset p = d.localPosition;
                final int x = (p.dx / cell).floor();
                final int y = (p.dy / cell).floor();
                if (x >= 0 && y >= 0 && x < c.width && y < c.height) {
                  widget.onCellTap(defaultModelVector.fromXY(x, y));
                }
              },
              child: CustomPaint(
                size: gridSize,
                painter: InteractiveGridLinePainter(
                  canvas: c,
                  cellPadding: 0.25,
                  showCoordinates: widget.showCoordinates,
                  showGrid: widget.blocCanvas.isOn, // usa el toggle real
                  coordinateColor: widget.coordinateColor,
                  origin: widget.origin,
                  destiny: widget.destiny,
                  previewPixels: widget.previewPixels,
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                ),
              ),
            );

            final bool needsH = gridSize.width > vp.width;
            final bool needsV = gridSize.height > vp.height;

            if (needsV) {
              content = SizedBox(
                height: vp.height,
                child: Scrollbar(
                  controller: _vCtrl,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _vCtrl,
                    primary: false,
                    child: content,
                  ),
                ),
              );
            }

            // Scroll horizontal por fuera (no afecta la altura gracias al SizedBox anterior)
            if (needsH) {
              content = Scrollbar(
                controller: _hCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _hCtrl,
                  primary: false,
                  scrollDirection: Axis.horizontal,
                  child: content,
                ),
              );
            }

            // Si no requiere scroll, céntralo
            if (!needsH && !needsV) {
              return Center(child: content);
            }
            return content;
          },
        );
      },
    );
  }
}
