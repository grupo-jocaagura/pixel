import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../app/blocs/bloc_canvas.dart';

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

  List<String> _suggestX() =>
      List<String>.generate(blocCanvas.canvas.width, (int i) => '$i');
  List<String> _suggestY() =>
      List<String>.generate(blocCanvas.canvas.height, (int i) => '$i');

  String? _validateX(String? v) {
    if (v == null || v.isEmpty) {
      return 'requerido';
    }
    final int? n = int.tryParse(v);
    if (n == null) {
      return 'número inválido';
    }
    if (n < 0 || n >= blocCanvas.canvas.width) {
      return 'fuera de rango';
    }
    return null;
  }

  String? _validateY(String? v) {
    if (v == null || v.isEmpty) {
      return 'requerido';
    }
    final int? n = int.tryParse(v);
    if (n == null) {
      return 'número inválido';
    }
    if (n < 0 || n >= blocCanvas.canvas.height) {
      return 'fuera de rango';
    }
    return null;
  }

  Widget _coordEditor({
    required String label,
    required Point<int>? value,
    required void Function(Point<int>?) setValue,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InlineTextWidget(label),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: CustomAutoCompleteInputWidget(
            label: 'x',
            initialData: value?.x.toString() ?? '',
            placeholder: 'x',
            suggestList: _suggestX(),
            textInputType: TextInputType.number,
            onChangedDebounce: const Duration(milliseconds: 120),
            onEditingValidateFunction: _validateX,
            onChanged: (String v) {
              final int? x = int.tryParse(v);
              if (x == null) {
                return;
              }
              setValue(
                Point<int>(
                  x.clamp(0, blocCanvas.canvas.width - 1),
                  value?.y ?? 0,
                ),
              );
            },
            onFieldSubmitted: (String v) {
              final int? x = int.tryParse(v);
              if (x == null) {
                return;
              }
              setValue(
                Point<int>(
                  x.clamp(0, blocCanvas.canvas.width - 1),
                  value?.y ?? 0,
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: CustomAutoCompleteInputWidget(
            label: 'y',
            initialData: value?.y.toString() ?? '',
            placeholder: 'y',
            suggestList: _suggestY(),
            textInputType: TextInputType.number,
            onChangedDebounce: const Duration(milliseconds: 120),
            onEditingValidateFunction: _validateY,
            onChanged: (String v) {
              final int? y = int.tryParse(v);
              if (y == null) {
                return;
              }
              setValue(
                Point<int>(
                  value?.x ?? 0,
                  y.clamp(0, blocCanvas.canvas.height - 1),
                ),
              );
            },
            onFieldSubmitted: (String v) {
              final int? y = int.tryParse(v);
              if (y == null) {
                return;
              }
              setValue(
                Point<int>(
                  value?.x ?? 0,
                  y.clamp(0, blocCanvas.canvas.height - 1),
                ),
              );
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
            _coordEditor(
              label: 'Origen',
              value: origin,
              setValue: onChangedOrigin,
            ),
            _coordEditor(
              label: 'Destino',
              value: destiny,
              setValue: onChangedDestiny,
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
            IconButton(
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
