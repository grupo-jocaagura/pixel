import 'package:flutter/material.dart';

class PixelIconButton extends StatelessWidget {
  const PixelIconButton({
    required this.tooltip,
    required this.icon,
    this.onPressed,

    super.key,
  });
  final Icon icon;
  final String tooltip;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(tooltip: tooltip, icon: icon, onPressed: onPressed);
  }
}
