import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import 'pixel_icon_button.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bool canPop = context.appManager.pageManager.canPop;

    return PixelIconButton(
      icon: canPop
          ? const Icon(Icons.arrow_back)
          : const Icon(Icons.multiple_stop),
      tooltip: canPop ? 'Volver' : 'No hay más páginas',
      onPressed: canPop ? context.appManager.pageManager.pop : null,
    );
  }
}
