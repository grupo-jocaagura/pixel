import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../app/utils/util_pixel_raster.dart';
import '../../domain/models/model_pixel.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/bottom_controls_widget.dart';
import '../widgets/interactive_grid_line_widget.dart';

class SpeakTheLinePage extends StatefulWidget {
  const SpeakTheLinePage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'speak-the-line',
    segments: <String>['speak-the-line'],
  );

  @override
  State<SpeakTheLinePage> createState() => _SpeakTheLinePageState();
}

class _SpeakTheLinePageState extends State<SpeakTheLinePage> {
  Point<int>? origin;
  Point<int>? destiny;
  bool showCoords = true;
  List<ModelPixel> preview = <ModelPixel>[];

  void _recomputePreview(BlocCanvas blocCanvas) {
    preview = <ModelPixel>[];
    if (origin != null && destiny != null) {
      preview = UtilPixelRaster.rasterLinePixels(
        canvas: blocCanvas.canvas,
        origin: ModelPixel.fromCoord(
          origin!.x,
          origin!.y,
          hexColor: blocCanvas.selectedHex,
        ),
        destiny: ModelPixel.fromCoord(
          destiny!.x,
          destiny!.y,
          hexColor: blocCanvas.selectedHex,
        ),
      );
    }
  }

  void _applyLine(BlocCanvas blocCanvas) {
    if (origin == null || destiny == null) {
      return;
    }
    blocCanvas.drawLine(
      ModelPixel.fromCoord(
        origin!.x,
        origin!.y,
        hexColor: blocCanvas.selectedHex,
      ),
      ModelPixel.fromCoord(
        destiny!.x,
        destiny!.y,
        hexColor: blocCanvas.selectedHex,
      ),
    );
    setState(() => preview = <ModelPixel>[]);
  }

  @override
  Widget build(BuildContext context) {
    final BlocCanvas blocCanvas = context.appManager
        .requireModuleByKey<BlocCanvas>(BlocCanvas.name);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButtonWidget(),
        title: const Text('SpeakTheLine — Raster line demo'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.layers_clear),
            onPressed: () => setState(() {
              origin = null;
              destiny = null;
              preview = <ModelPixel>[];
            }),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: InteractiveGridLineWidget(
              fit: GridFit.width,
              minCellDp: 2.0,
              blocCanvas: blocCanvas,
              showCoordinates: showCoords,
              coordinateColor: blocCanvas.selectedColor,
              origin: origin,
              destiny: destiny,
              previewPixels: preview,
              onCellTap: (Point<int> cell) {
                setState(() {
                  if (origin == null) {
                    origin = cell;
                  } else if (destiny == null) {
                    destiny = cell;
                  } else {
                    origin = cell;
                    destiny = null;
                  }
                  _recomputePreview(blocCanvas);
                });
              },
            ),
          ),
          BottomControlsWidget(
            blocCanvas: blocCanvas,
            origin: origin,
            destiny: destiny,
            showCoords: showCoords,
            onChangedOrigin: (Point<int>? p) {
              setState(() {
                origin = p;
                _recomputePreview(blocCanvas);
              });
            },
            onChangedDestiny: (Point<int>? p) {
              setState(() {
                destiny = p;
                _recomputePreview(blocCanvas);
              });
            },
            onToggleCoords: (bool v) => setState(() => showCoords = v),
            onDraw: () => _applyLine(blocCanvas),
          ),
        ],
      ),
    );
  }
}
