import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../../app/blocs/bloc_canvas.dart';

class CoordEditorWidget extends StatelessWidget {
  const CoordEditorWidget({
    required this.label,
    required this.value,
    required this.setValue,
    required this.blocCanvas,
    super.key,
  });

  final String label;
  final Point<int>? value;
  final void Function(Point<int>?) setValue;
  final BlocCanvas blocCanvas;

  String? validateX(String? v) {
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

  String? validateY(String? v) {
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

  @override
  Widget build(BuildContext context) {
    List<String> suggestX() =>
        List<String>.generate(blocCanvas.canvas.width, (int i) => '$i');
    List<String> suggestY() =>
        List<String>.generate(blocCanvas.canvas.height, (int i) => '$i');

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
            suggestList: suggestX(),
            textInputType: TextInputType.number,
            onChangedDebounce: const Duration(milliseconds: 120),
            onEditingValidateFunction: validateX,
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
            suggestList: suggestY(),
            textInputType: TextInputType.number,
            onChangedDebounce: const Duration(milliseconds: 120),
            onEditingValidateFunction: validateY,
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
}
