import 'package:flutter/material.dart';

class PolicyTableWidget extends StatelessWidget {
  const PolicyTableWidget({required this.rows, super.key});
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final TextStyle head = Theme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700);
    final TextStyle cell = Theme.of(context).textTheme.bodyMedium!;
    final Color border = Theme.of(context).dividerColor.withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.symmetric(inside: BorderSide(color: border)),
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(0.9),
          1: FlexColumnWidth(1.1),
          2: FlexColumnWidth(),
        },
        children: <TableRow>[
          TableRow(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
            children: rows.first.map((String h) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText(h, style: head),
              );
            }).toList(),
          ),
          ...rows.skip(1).map((List<String> r) {
            return TableRow(
              children: r.map((String c) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: SelectableText(c, style: cell),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}
