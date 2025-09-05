import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../app/blocs/bloc_canvas_preview.dart';
import '../../domain/states/state_preview.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/bottom_controls_widget.dart';
import '../widgets/interactive_grid_line_widget.dart';
import '../widgets/pixel_icon_button.dart';

class SpeakTheLinePage extends StatelessWidget {
  const SpeakTheLinePage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'speak-the-line',
    segments: <String>['speak-the-line'],
  );

  @override
  Widget build(BuildContext context) {
    final BlocCanvas canvasBloc = context.appManager
        .requireModuleByKey<BlocCanvas>(BlocCanvas.name);
    final BlocCanvasPreview previewBloc = context.appManager
        .requireModuleByKey<BlocCanvasPreview>(BlocCanvasPreview.name);

    // Asegura herramienta LINE al entrar (idempotente)
    previewBloc.setTool(
      DrawTool.line,
      canvasBloc.canvas,
      canvasBloc.selectedHex,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButtonWidget(),
        title: const Text('SpeakTheLine — Raster line demo'),
        actions: <Widget>[
          PixelIconButton(
            tooltip: 'Limpiar selección',
            icon: const Icon(Icons.layers_clear),
            onPressed: () => previewBloc.clearSelection(
              canvasBloc.canvas,
              canvasBloc.selectedHex,
            ),
          ),
        ],
      ),
      body: StreamBuilder<StatePreview>(
        stream: previewBloc.stateStream,
        initialData: previewBloc.state,
        builder: (_, __) {
          final StatePreview state = previewBloc.state;

          return Column(
            children: <Widget>[
              Expanded(
                child: InteractiveGridLineWidget(
                  fit: GridFit.width,
                  blocCanvas: canvasBloc,
                  showCoordinates: state.showCoords,
                  coordinateColor: canvasBloc.selectedColor,
                  origin: state.origin,
                  destiny: state.destiny,
                  previewPixels: state.previewPixels,
                  onCellTap: (Point<int> cell) => previewBloc.tapCell(
                    cell,
                    canvasBloc.canvas,
                    canvasBloc.selectedHex,
                  ),
                ),
              ),
              BottomControlsWidget(
                blocCanvas: canvasBloc,
                origin: state.origin,
                destiny: state.destiny,
                showCoords: state.showCoords,
                onChangedOrigin: (Point<int>? point) => previewBloc.setOrigin(
                  point,
                  canvasBloc.canvas,
                  canvasBloc.selectedHex,
                ),
                onChangedDestiny: (Point<int>? point) => previewBloc.setDestiny(
                  point,
                  canvasBloc.canvas,
                  canvasBloc.selectedHex,
                ),
                onToggleCoords: (bool value) => previewBloc.setShowCoords(
                  value,
                  canvasBloc.canvas,
                  canvasBloc.selectedHex,
                ),
                onDraw: () => previewBloc.apply(canvasBloc),
              ),
            ],
          );
        },
      ),
    );
  }
}
