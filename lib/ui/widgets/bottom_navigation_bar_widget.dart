import 'package:flutter/material.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../domain/models/model_canvas.dart';
import 'forms/custom_auto_complete_widget.dart';
import 'grid_line_toggle_widget.dart';

String _value = '80'; // Valor por defecto para la resolución

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({required this.blocCanvas, super.key});

  final BlocCanvas blocCanvas;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: StreamBuilder<Color>(
          stream: blocCanvas.selectedColorStream,
          builder: (_, __) {
            return Row(
              children: <Widget>[
                const Text('Color: '),
                for (final Color color in <Color>[
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  Colors.black,
                ])
                  GestureDetector(
                    onTap: () => blocCanvas.updateSelectedColor(color),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: blocCanvas.selectedColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                // Nuevo: Botón para resetear el canvas
                const SizedBox(width: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Resetear'),
                  onPressed: blocCanvas.resetCanvas,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 24),
                // Nuevo: Selector de resolución
                SizedBox(
                  width: 120,
                  child: CustomAutoCompleteInputWidget(
                    onEditingValueFunction: (String value) => _value = value,
                    onEditingValidateFunction:
                        blocCanvas.validateResolutionValue,
                    onPressedValueFunction:
                        blocCanvas.updateResolutionFromString,
                    label: 'Resolución',
                    initialData: blocCanvas.canvas.width.toString(),
                    placeholder: 'Resolución',
                    textInputType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.blue),
                  tooltip: 'Actualizar resolución',
                  onPressed: () =>
                      blocCanvas.updateResolutionFromString(_value),
                ),
                const SizedBox(width: 8),
                // Nuevo: Mostrar resolución actual
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: StreamBuilder<ModelCanvas>(
                    stream: blocCanvas.canvasStream,
                    builder: (_, __) {
                      return InlineTextWidget(
                        blocCanvas.resolution,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                GridLineToggle(blocCanvas: blocCanvas),
              ],
            );
          },
        ),
      ),
    );
  }
}
