import 'package:flutter/material.dart';

class SubSectionWidget extends StatelessWidget {
  const SubSectionWidget({
    required this.subtitle,
    super.key,
    this.paragraphs,
    this.bullets,
  });

  final String subtitle;
  final List<String>? paragraphs;
  final List<String>? bullets;

  @override
  Widget build(BuildContext context) {
    final TextStyle h3 = Theme.of(
      context,
    ).textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w700);
    final TextStyle body = Theme.of(context).textTheme.bodyMedium!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SelectableText(subtitle, style: h3),
          if (paragraphs != null)
            ...paragraphs!.map(
              (String p) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText(p, style: body),
              ),
            ),
          if (bullets != null)
            ...bullets!.map(
              (String b) => Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('•  '),
                    Expanded(child: SelectableText(b, style: body)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
