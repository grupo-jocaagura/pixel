import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../app/utils/util_pixel_raster.dart';
import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../painters/interactive_grid_line_painter.dart';
import '../widgets/back_button_widget.dart';

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

  void _onTapGrid(Offset localPosition, Size size, ModelCanvas c) {
    final double cw = size.width / c.width;
    final double ch = size.height / c.height;
    final int x = (localPosition.dx / cw).floor();
    final int y = (localPosition.dy / ch).floor();
    if (x < 0 || y < 0 || x >= c.width || y >= c.height) {
      return;
    }

    setState(() {
      if (origin == null) {
        origin = Point<int>(x, y);
      } else if (destiny == null) {
        destiny = Point<int>(x, y);
      } else {
        origin = Point<int>(x, y);
        destiny = null;
      }
      _recomputePreview(context);
    });
  }

  void _recomputePreview(BuildContext context) {
    final BlocCanvas blocCanvas = context.appManager
        .requireModuleByKey<BlocCanvas>(BlocCanvas.name);

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

  void _applyLine(BuildContext context) {
    final BlocCanvas blocCanvas = context.appManager
        .requireModuleByKey<BlocCanvas>(BlocCanvas.name);
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
        title: const Text('SpeakTheLine — Raster line demo'),
        leading: const BackButtonWidget(),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.layers_clear),
            onPressed: () {
              setState(() {
                origin = null;
                destiny = null;
                preview = <ModelPixel>[];
              });
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // Área de canvas
          Expanded(
            child: LayoutBuilder(
              builder: (_, BoxConstraints constraints) {
                final Size area = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return GestureDetector(
                  onTapDown: (TapDownDetails d) =>
                      _onTapGrid(d.localPosition, area, blocCanvas.canvas),
                  child: CustomPaint(
                    painter: InteractiveGridLinePainter(
                      canvas: blocCanvas.canvas,
                      cellPadding: 0.5,
                      showCoordinates: showCoords,
                      coordinateColor: blocCanvas.selectedColor,
                      origin: origin,
                      destiny: destiny,
                      previewPixels: preview,
                    ),
                    size: area,
                  ),
                );
              },
            ),
          ),
          // Barra inferior
          _BottomControls(
            canvas: blocCanvas.canvas,
            origin: origin,
            destiny: destiny,
            showCoords: showCoords,
            onChangedOrigin: (Point<int>? p) {
              setState(() {
                origin = p;
                _recomputePreview(context);
              });
            },
            onChangedDestiny: (Point<int>? p) {
              setState(() {
                destiny = p;
                _recomputePreview(context);
              });
            },
            onToggleCoords: (bool v) => setState(() => showCoords = v),
            onDraw: () => _applyLine(context),
          ),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.canvas,
    required this.origin,
    required this.destiny,
    required this.showCoords,
    required this.onChangedOrigin,
    required this.onChangedDestiny,
    required this.onToggleCoords,
    required this.onDraw,
  });

  final ModelCanvas canvas;
  final Point<int>? origin;
  final Point<int>? destiny;
  final bool showCoords;
  final ValueChanged<Point<int>?> onChangedOrigin;
  final ValueChanged<Point<int>?> onChangedDestiny;
  final ValueChanged<bool> onToggleCoords;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
    int clampX(int v) => v.clamp(0, canvas.width - 1);
    int clampY(int v) => v.clamp(0, canvas.height - 1);

    Widget coordEditor(
      String label,
      Point<int>? value,
      void Function(Point<int>?) setValue,
    ) {
      final TextEditingController cx = TextEditingController(
        text: '${value?.x ?? ''}',
      );
      final TextEditingController cy = TextEditingController(
        text: '${value?.y ?? ''}',
      );
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: TextField(
              controller: cx,
              decoration: const InputDecoration(labelText: 'x'),
              keyboardType: TextInputType.number,
              onSubmitted: (String s) {
                final int? x = int.tryParse(s);
                if (x == null) {
                  return;
                }
                setValue(Point<int>(clampX(x), value?.y ?? 0));
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: TextField(
              controller: cy,
              decoration: const InputDecoration(labelText: 'y'),
              keyboardType: TextInputType.number,
              onSubmitted: (String s) {
                final int? y = int.tryParse(s);
                if (y == null) {
                  return;
                }
                setValue(Point<int>(value?.x ?? 0, clampY(y)));
              },
            ),
          ),
          IconButton(
            tooltip: 'Clear',
            icon: const Icon(Icons.clear),
            onPressed: () => setValue(null),
          ),
        ],
      );
    }

    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            coordEditor('Origen', origin, onChangedOrigin),
            coordEditor('Destino', destiny, onChangedDestiny),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text('Mostrar coord'),
                Switch(value: showCoords, onChanged: onToggleCoords),
              ],
            ),
            ElevatedButton.icon(
              onPressed: (origin != null && destiny != null) ? onDraw : null,
              icon: const Icon(Icons.show_chart),
              label: const Text('Dibujar línea'),
            ),
          ],
        ),
      ),
    );
  }
}
