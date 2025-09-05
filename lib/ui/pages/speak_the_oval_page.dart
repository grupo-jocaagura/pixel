// ui/pages/speak_the_oval_page.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../app/blocs/bloc_canvas_preview.dart';
import '../../domain/states/state_preview.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/forms/coord_editor_widget.dart';
import '../widgets/interactive_grid_line_widget.dart';
import '../widgets/pixel_icon_button.dart';

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
          final StatePreview s = previewBloc.state;

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
                  onCellTap: (Point<int> cell) => previewBloc.tapCell(
                    cell,
                    canvasBloc.canvas,
                    canvasBloc.selectedHex,
                  ),
                ),
              ),
              _BottomControlsOval(
                canvasBloc: canvasBloc,
                previewBloc: previewBloc,
                state: s,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomControlsOval extends StatelessWidget {
  const _BottomControlsOval({
    required this.canvasBloc,
    required this.previewBloc,
    required this.state,
  });

  final BlocCanvas canvasBloc;
  final BlocCanvasPreview previewBloc;
  final StatePreview state;

  String? _validateStroke(String? v) {
    if (v == null || v.isEmpty) {
      return 'requerido';
    }
    final int? n = int.tryParse(v);
    if (n == null || n < 1) {
      return 'mínimo 1';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String pendingRes = canvasBloc.canvas.width.toString();

    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: <Widget>[
            CoordEditorWidget(
              label: 'P1',
              value: state.origin,
              setValue: (Point<int>? p) => previewBloc.setOrigin(
                p,
                canvasBloc.canvas,
                canvasBloc.selectedHex,
              ),
              blocCanvas: canvasBloc,
            ),
            CoordEditorWidget(
              label: 'P2',
              value: state.destiny,
              setValue: (Point<int>? p) => previewBloc.setDestiny(
                p,
                canvasBloc.canvas,
                canvasBloc.selectedHex,
              ),
              blocCanvas: canvasBloc,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const InlineTextWidget('Relleno'),
                Switch(
                  value: state.fill,
                  onChanged: (bool v) => previewBloc.setFill(
                    v,
                    canvasBloc.canvas,
                    canvasBloc.selectedHex,
                  ),
                ),
              ],
            ),
            SizedBox(
              width: 120,
              child: CustomAutoCompleteInputWidget(
                label: 'Stroke',
                initialData: state.stroke.toString(),
                placeholder: '≥ 1',
                textInputType: TextInputType.number,
                suggestList: const <String>['1', '2', '3', '4', '5', '8'],
                onChangedDebounce: const Duration(milliseconds: 120),
                onEditingValidateFunction: _validateStroke,
                onChanged: (String v) {
                  final int? n = int.tryParse(v);
                  if (n != null && n >= 1) {
                    previewBloc.setStroke(
                      n,
                      canvasBloc.canvas,
                      canvasBloc.selectedHex,
                    );
                  }
                },
                onFieldSubmitted: (String v) {
                  final int? n = int.tryParse(v);
                  if (n != null && n >= 1) {
                    previewBloc.setStroke(
                      n,
                      canvasBloc.canvas,
                      canvasBloc.selectedHex,
                    );
                  }
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: state.hasSelection
                  ? () => previewBloc.apply(canvasBloc)
                  : null,
              icon: const Icon(Icons.egg_alt_outlined),
              label: const Text('Dibujar óvalo'),
            ),
            // (opcional) resolución igual que otras pages
            SizedBox(
              width: 140,
              child: CustomAutoCompleteInputWidget(
                label: 'Resolución',
                initialData: canvasBloc.canvas.width.toString(),
                placeholder: 'N (NxN)',
                textInputType: TextInputType.number,
                suggestList: const <String>['10', '20', '40', '80', '160'],
                onEditingValidateFunction: (String? value) => canvasBloc
                    .validateResolutionValue(Utils.getStringFromDynamic(value)),
                onChanged: (String v) => pendingRes = v,
                onFieldSubmitted: (String v) {
                  pendingRes = v;
                  canvasBloc.updateResolutionFromString(pendingRes);
                },
              ),
            ),
            PixelIconButton(
              tooltip: 'Aplicar resolución',
              icon: const Icon(Icons.check_circle, color: Colors.blue),
              onPressed: () =>
                  canvasBloc.updateResolutionFromString(pendingRes),
            ),
          ],
        ),
      ),
    );
  }
}
