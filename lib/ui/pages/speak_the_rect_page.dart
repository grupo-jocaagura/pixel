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

/// Stateless page that previews and applies rectangle drawing commands
/// using BlocCanvas + BlocCanvasPreview (StatePreview).
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

    // Idempotente: asegura herramienta Rect al entrar.
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
                  onCellTap: (Point<int> cell) => previewBloc.tapCell(
                    cell,
                    canvasBloc.canvas,
                    canvasBloc.selectedHex,
                  ),
                ),
              ),

              _BottomControlsRect(
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

class _BottomControlsRect extends StatelessWidget {
  const _BottomControlsRect({
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
    if (n > 999) {
      return 'demasiado grande';
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
            // Origen / Destino (reutiliza tu editor de coords)
            CoordEditorWidget(
              label: 'Origen',
              value: state.origin,
              setValue: (Point<int>? p) => previewBloc.setOrigin(
                p,
                canvasBloc.canvas,
                canvasBloc.selectedHex,
              ),
              blocCanvas: canvasBloc,
            ),
            CoordEditorWidget(
              label: 'Destino',
              value: state.destiny,
              setValue: (Point<int>? p) => previewBloc.setDestiny(
                p,
                canvasBloc.canvas,
                canvasBloc.selectedHex,
              ),
              blocCanvas: canvasBloc,
            ),

            // Mostrar coordenadas
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const InlineTextWidget('Mostrar coord'),
                Switch(
                  value: state.showCoords,
                  onChanged: (bool v) => previewBloc.setShowCoords(
                    v,
                    canvasBloc.canvas,
                    canvasBloc.selectedHex,
                  ),
                ),
              ],
            ),

            // Fill
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

            // Stroke (con debounce para evitar chispazos)
            SizedBox(
              width: 140,
              child: CustomAutoCompleteInputWidget(
                label: 'Stroke',
                initialData: state.stroke.toString(),
                placeholder: '≥ 1',
                textInputType: TextInputType.number,
                suggestList: const <String>['1', '2', '3', '4', '5', '8', '10'],
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
              icon: const Icon(Icons.crop_square_rounded),
              label: const Text('Dibujar rect'),
            ),

            // --- (Opcional) Resolución como en Line ---
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
