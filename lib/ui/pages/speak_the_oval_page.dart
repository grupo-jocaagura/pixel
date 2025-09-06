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

class SpeakTheOvalPage extends StatelessWidget {
  const SpeakTheOvalPage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'speak-the-oval',
    segments: <String>['speak-the-oval'],
  );

  @override
  Widget build(BuildContext context) {
    final BlocCanvas canvasBloc = context.appManager
        .requireModuleByKey<BlocCanvas>(BlocCanvas.name);
    final BlocCanvasPreview previewBloc = context.appManager
        .requireModuleByKey<BlocCanvasPreview>(BlocCanvasPreview.name);

    previewBloc.setTool(
      DrawTool.oval,
      canvasBloc.canvas,
      canvasBloc.selectedHex,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButtonWidget(),
        title: const Text('SpeakTheOval — Raster oval demo'),
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
                  onCellTap: (ModelVector cell) => previewBloc.tapCell(
                    cell,
                    canvasBloc.canvas,
                    canvasBloc.selectedHex,
                  ),
                ),
              ),
              PreviewControlsWidget(
                canvasBloc: canvasBloc,
                previewBloc: previewBloc,
                state: state,
                applyLabel: 'Dibujar óvalo',
                applyIcon: Icons.egg_alt_outlined,
                coordinatesEditor: Wrap(
                  spacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    CoordEditorWidget(
                      label: 'P1',
                      value: state.origin,
                      setValue: (ModelVector? point) => previewBloc.setOrigin(
                        point,
                        canvasBloc.canvas,
                        canvasBloc.selectedHex,
                      ),
                      blocCanvas: canvasBloc,
                    ),
                    CoordEditorWidget(
                      label: 'P2',
                      value: state.destiny,
                      setValue: (ModelVector? point) => previewBloc.setDestiny(
                        point,
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
