import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

class NotFoundRoutePage extends StatelessWidget {
  const NotFoundRoutePage({super.key});
  static const PageModel pageModel = PageModel(
    name: 'NotFoundRoutePage',
    segments: <String>['not-found'],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const InlineTextWidget('Not Found')),
      body: const Center(
        child: InlineTextWidget(
          'The requested route does not exist.',
          style: TextStyle(fontSize: 24, color: Colors.red),
        ),
      ),
    );
  }
}
