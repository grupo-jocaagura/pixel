import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../app/blocs/bloc_canvas_preview.dart';
import '../../domain/states/state_preview.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/forms/coord_editor_widget.dart';
import '../widgets/interactive_grid_line_widget.dart';
import '../widgets/pixel_icon_button.dart';
import '../widgets/preview_controls_widget.dart';

class SpeakTheRectPage extends StatelessWidget {
  const SpeakTheRectPage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'speak-the-rect',
    segments: <String>['speak-the-rect'],
  );

  @override
  Widget build(BuildContext context) {
    final BlocCanvas canvasBloc = context.appManager
        .requireModuleByKey<BlocCanvas>(BlocCanvas.name);
    final BlocCanvasPreview previewBloc = context.appManager
        .requireModuleByKey<BlocCanvasPreview>(BlocCanvasPreview.name);

    // Configurar herramienta rect al entrar
    previewBloc.setTool(
      DrawTool.rect,
      canvasBloc.canvas,
      canvasBloc.selectedHex,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButtonWidget(),
        title: const Text('SpeakTheRect — Raster rectangle demo'),
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
        builder: (_, AsyncSnapshot<StatePreview> snap) {
          final StatePreview s = snap.data ?? previewBloc.state;

          return Column(
            children: <Widget>[
              Expanded(
                child: InteractiveGridLineWidget(
                  fit: GridFit.width,
                  blocCanvas: canvasBloc,
                  showCoordinates: s.showCoords,
                  coordinateColor: canvasBloc.selectedColor,
                  origin: s.origin,
                  destiny: s.destiny,
                  previewPixels: s.previewPixels,
                  onCellTap: (Point<int> cell) {
                    previewBloc.tapCell(
                      cell,
                      canvasBloc.canvas,
                      canvasBloc.selectedHex,
                    );
                  },
                ),
              ),
              PreviewControlsWidget(
                canvasBloc: canvasBloc,
                previewBloc: previewBloc,
                state: s,
                applyLabel: 'Dibujar rect',
                applyIcon: Icons.crop_square,
                coordinatesEditor: Wrap(
                  spacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    CoordEditorWidget(
                      label: 'P1',
                      value: s.origin,
                      setValue: (Point<int>? p) => previewBloc.setOrigin(
                        p,
                        canvasBloc.canvas,
                        canvasBloc.selectedHex,
                      ),
                      blocCanvas: canvasBloc,
                    ),
                    CoordEditorWidget(
                      label: 'P2',
                      value: s.destiny,
                      setValue: (Point<int>? p) => previewBloc.setDestiny(
                        p,
                        canvasBloc.canvas,
                        canvasBloc.selectedHex,
                      ),
                      blocCanvas: canvasBloc,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PreviewControlsCommon {}
