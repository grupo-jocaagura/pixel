import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../app/blocs/bloc_canvas.dart';
import 'forms/coord_editor_widget.dart';
import 'pixel_icon_button.dart';

class BottomControlsWidget extends StatelessWidget {
  const BottomControlsWidget({
    required this.blocCanvas,
    required this.origin,
    required this.destiny,
    required this.showCoords,
    required this.onChangedOrigin,
    required this.onChangedDestiny,
    required this.onToggleCoords,
    required this.onDraw,
    super.key,
  });

  final BlocCanvas blocCanvas;
  final Point<int>? origin;
  final Point<int>? destiny;
  final bool showCoords;
  final ValueChanged<Point<int>?> onChangedOrigin;
  final ValueChanged<Point<int>?> onChangedDestiny;
  final ValueChanged<bool> onToggleCoords;
  final VoidCallback onDraw;

  @override
  Widget build(BuildContext context) {
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
              label: 'Origen',
              value: origin,
              setValue: onChangedOrigin,
              blocCanvas: blocCanvas,
            ),
            CoordEditorWidget(
              label: 'Destino',
              value: destiny,
              setValue: onChangedDestiny,
              blocCanvas: blocCanvas,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const InlineTextWidget('Mostrar coord'),
                Switch(value: showCoords, onChanged: onToggleCoords),
              ],
            ),
            ElevatedButton.icon(
              onPressed: (origin != null && destiny != null) ? onDraw : null,
              icon: const Icon(Icons.show_chart),
              label: const Text('Dibujar línea'),
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
