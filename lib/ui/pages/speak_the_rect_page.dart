import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../app/utils/util_pixel_raster.dart';
import '../../domain/models/model_pixel.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/forms/coord_editor_widget.dart';
import '../widgets/interactive_grid_line_widget.dart';
import '../widgets/pixel_icon_button.dart';

class SpeakTheRectPage extends StatefulWidget {
  const SpeakTheRectPage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'speak-the-rect',
    segments: <String>['speak-the-rect'],
  );

  @override
  State<SpeakTheRectPage> createState() => _SpeakTheRectPageState();
}

class _SpeakTheRectPageState extends State<SpeakTheRectPage> {
  Point<int>? p1;
  Point<int>? p2;
  bool showCoords = true;
  bool fill = false;
  int stroke = 1;

  List<ModelPixel> preview = <ModelPixel>[];

  void _recomputePreview(BlocCanvas blocCanvas) {
    preview = <ModelPixel>[];
    if (p1 != null && p2 != null) {
      preview = UtilPixelRaster.rasterRectPixels(
        canvas: blocCanvas.canvas,
        p1: ModelPixel.fromCoord(
          p1!.x,
          p1!.y,
          hexColor: blocCanvas.selectedHex,
        ),
        p2: ModelPixel.fromCoord(
          p2!.x,
          p2!.y,
          hexColor: blocCanvas.selectedHex,
        ),
        hexColor: blocCanvas.selectedHex,
        fill: fill,
        stroke: stroke,
      );
    }
  }

  void _apply(BlocCanvas blocCanvas) {
    if (p1 == null || p2 == null) {
      return;
    }
    blocCanvas.drawRectCorners(
      ModelPixel.fromCoord(p1!.x, p1!.y, hexColor: blocCanvas.selectedHex),
      ModelPixel.fromCoord(p2!.x, p2!.y, hexColor: blocCanvas.selectedHex),
      fill: fill,
      stroke: stroke,
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
        title: const Text('SpeakTheRect — Raster rectangle demo'),
        actions: <Widget>[
          PixelIconButton(
            tooltip: 'Limpiar selección',
            icon: const Icon(Icons.layers_clear),
            onPressed: () => setState(() {
              p1 = null;
              p2 = null;
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
              blocCanvas: blocCanvas,
              showCoordinates: showCoords,
              coordinateColor: blocCanvas.selectedColor,
              origin: p1,
              destiny: p2,
              minCellDp: 1.0 / MediaQuery.of(context).devicePixelRatio,
              previewPixels: preview,
              onCellTap: (Point<int> cell) {
                setState(() {
                  if (p1 == null) {
                    p1 = cell;
                  } else if (p2 == null) {
                    p2 = cell;
                  } else {
                    p1 = cell;
                    p2 = null;
                  }
                  _recomputePreview(blocCanvas);
                });
              },
            ),
          ),
          _BottomControlsRect(
            blocCanvas: blocCanvas,
            p1: p1,
            p2: p2,
            showCoords: showCoords,
            fill: fill,
            stroke: stroke,
            onChangedP1: (Point<int>? v) {
              setState(() {
                p1 = v;
                _recomputePreview(blocCanvas);
              });
            },
            onChangedP2: (Point<int>? v) {
              setState(() {
                p2 = v;
                _recomputePreview(blocCanvas);
              });
            },
            onToggleCoords: (bool v) => setState(() => showCoords = v),
            onToggleFill: (bool v) {
              setState(() {
                fill = v;
                _recomputePreview(blocCanvas);
              });
            },
            onChangedStroke: (int v) {
              setState(() {
                stroke = v;
                _recomputePreview(blocCanvas);
              });
            },
            onApply: () => _apply(blocCanvas),
          ),
        ],
      ),
    );
  }
}

class _BottomControlsRect extends StatelessWidget {
  const _BottomControlsRect({
    required this.blocCanvas,
    required this.p1,
    required this.p2,
    required this.showCoords,
    required this.fill,
    required this.stroke,
    required this.onChangedP1,
    required this.onChangedP2,
    required this.onToggleCoords,
    required this.onToggleFill,
    required this.onChangedStroke,
    required this.onApply,
  });

  final BlocCanvas blocCanvas;
  final Point<int>? p1;
  final Point<int>? p2;
  final bool showCoords;
  final bool fill;
  final int stroke;

  final ValueChanged<Point<int>?> onChangedP1;
  final ValueChanged<Point<int>?> onChangedP2;
  final ValueChanged<bool> onToggleCoords;
  final ValueChanged<bool> onToggleFill;
  final ValueChanged<int> onChangedStroke;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    void deferStroke(int n) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onChangedStroke(n));
    }

    String pendingRes = blocCanvas.canvas.width.toString();
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            CoordEditorWidget(
              label: 'P1',
              value: p1,
              setValue: onChangedP1,
              blocCanvas: blocCanvas,
            ),
            CoordEditorWidget(
              label: 'P2',
              value: p2,
              setValue: onChangedP2,
              blocCanvas: blocCanvas,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const InlineTextWidget('Fill'),
                Switch(value: fill, onChanged: onToggleFill),
              ],
            ),
            if (!fill)
              SizedBox(
                width: 120,
                child: CustomAutoCompleteInputWidget(
                  label: 'Stroke',
                  initialData: '$stroke',
                  placeholder: 'grosor',
                  textInputType: TextInputType.number,
                  suggestList: const <String>[
                    '1',
                    '2',
                    '3',
                    '4',
                    '5',
                    '6',
                    '8',
                    '10',
                  ],
                  onEditingValidateFunction: (String? v) {
                    final int? n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) {
                      return 'inválido';
                    }
                    // opcional: clamp por tamaño actual
                    return null;
                  },
                  onChanged: (String v) {
                    final int? n = int.tryParse(v);
                    if (n != null && n > 0) {
                      deferStroke(n);
                    }
                  },
                  onFieldSubmitted: (String v) {
                    final int? n = int.tryParse(v);
                    if (n != null && n > 0) {
                      deferStroke(n);
                    }
                  },
                ),
              ),

            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const InlineTextWidget('Mostrar coord'),
                Switch(value: showCoords, onChanged: onToggleCoords),
              ],
            ),
            ElevatedButton.icon(
              onPressed: (p1 != null && p2 != null) ? onApply : null,
              icon: const Icon(Icons.crop_square),
              label: const Text('Dibujar rect'),
            ),
            // --- Resolución (cuadrada) como en el BottomNavigationBarWidget
            SizedBox(
              width: 140,
              child: CustomAutoCompleteInputWidget(
                label: 'Resolución',
                initialData: blocCanvas.canvas.width.toString(),
                placeholder: 'N (NxN)',
                textInputType: TextInputType.number,
                suggestList: const <String>['10', '20', '40', '80', '160'],
                onEditingValidateFunction: (String? value) => blocCanvas
                    .validateResolutionValue(Utils.getStringFromDynamic(value)),
                onChanged: (String v) => pendingRes = v,
                onFieldSubmitted: (String v) {
                  pendingRes = v;
                  blocCanvas.updateResolutionFromString(pendingRes);
                },
              ),
            ),
            PixelIconButton(
              tooltip: 'Aplicar resolución',
              icon: const Icon(Icons.check_circle, color: Colors.blue),
              onPressed: () =>
                  blocCanvas.updateResolutionFromString(pendingRes),
            ),
          ],
        ),
      ),
    );
  }
}
