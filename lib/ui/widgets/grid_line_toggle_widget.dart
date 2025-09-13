import 'package:flutter/material.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../app/blocs/bloc_canvas.dart';

/// Un toggle compacto para las líneas de la cuadrícula.
class GridLineToggle extends StatelessWidget {
  const GridLineToggle({required this.blocCanvas, super.key});
  final BlocCanvas blocCanvas;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Color>(
      stream: blocCanvas.gridLineColorStream,
      initialData: blocCanvas.gridLineColor,
      builder: (_, AsyncSnapshot<Color> snapshot) {
        final bool isOn = blocCanvas.isOn;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const InlineTextWidget('Grid'),
            const SizedBox(width: 4),
            Switch(
              value: isOn,
              activeThumbColor: blocCanvas.gridLineColor,
              onChanged: (_) => blocCanvas.toggleGridLineColor(),
            ),
          ],
        );
      },
    );
  }
}
