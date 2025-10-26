import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

class MenuTileWidget extends StatelessWidget {
  const MenuTileWidget({
    required this.label,
    required this.description,
    required this.page,
    super.key,
  });
  final String label;
  final String description;
  final PageModel page;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: InlineTextWidget(label),
      subtitle: ParagraphTextWidget(description),
      leading: const Icon(Icons.brush),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.appManager.pushModel(page);
      },
    );
  }
}
