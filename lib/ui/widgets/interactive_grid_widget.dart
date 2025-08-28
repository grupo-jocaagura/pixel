import 'package:flutter/material.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../domain/models/model_canvas.dart';
import '../painters/interactive_grid_painter.dart';

class InteractiveGridWidget extends StatelessWidget {
  const InteractiveGridWidget({required this.blocCanvas, super.key});
  final BlocCanvas blocCanvas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<ModelCanvas>(
        stream: blocCanvas.canvasStream,
        builder: (_, __) {
          return LayoutBuilder(
            builder: (_, BoxConstraints constraints) {
              final Size screenSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return GestureDetector(
                onTapDown: (TapDownDetails details) =>
                    blocCanvas.handleTapDown(details, screenSize),
                child: CustomPaint(
                  size: screenSize,
                  painter: InteractiveGridPainter(
                    modelCanvas: blocCanvas.canvas,
                    gridLineColor: blocCanvas.gridLineColor,
                    devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
