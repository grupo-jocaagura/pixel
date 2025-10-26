import 'package:flutter/material.dart';

import 'policy_table_widget.dart';
import 'sub_section_widget.dart';

class SectionWidget extends StatelessWidget {
  const SectionWidget({
    required this.title,
    required this.h2,
    required this.body,
    super.key,
    this.paragraphs,
    this.bullets,
    this.numbered,
    this.table,
    this.subSections,
  });

  final String title;
  final List<String>? paragraphs;
  final List<String>? bullets;
  final List<String>? numbered;
  final List<List<String>>? table;
  final List<SubSectionWidget>? subSections;
  final TextStyle? h2;
  final TextStyle? body;

  @override
  Widget build(BuildContext context) {
    final TextStyle h2s = h2 ?? Theme.of(context).textTheme.titleMedium!;
    final TextStyle bodyS = body ?? Theme.of(context).textTheme.bodyMedium!;
    final Color border = Theme.of(context).dividerColor.withValues(alpha: 0.4);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SelectableText(title, style: h2s),
          const SizedBox(height: 8),
          if (paragraphs != null)
            ...paragraphs!.map(
              (String p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SelectableText(p, style: bodyS),
              ),
            ),
          if (bullets != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bullets!
                    .map(
                      (String b) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('•  '),
                          Expanded(child: SelectableText(b, style: bodyS)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          if (numbered != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (int i = 0; i < numbered!.length; i++)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${i + 1}. '),
                        Expanded(
                          child: SelectableText(numbered![i], style: bodyS),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (subSections != null) ...subSections!.cast<Widget>(),
          if (table != null && table!.isNotEmpty)
            PolicyTableWidget(rows: table!),
        ],
      ),
    );
  }
}
