import 'package:flutter/material.dart';
import 'package:text_responsive/text_responsive.dart';

class SectionTitleWidget extends StatelessWidget {
  const SectionTitleWidget(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: InlineTextWidget(text),
    );
  }
}
