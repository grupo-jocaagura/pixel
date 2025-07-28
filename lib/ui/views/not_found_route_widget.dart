import 'package:flutter/material.dart';
import 'package:text_responsive/text_responsive.dart';

class NotFoundRouteWidget extends StatelessWidget {
  const NotFoundRouteWidget({super.key});

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
