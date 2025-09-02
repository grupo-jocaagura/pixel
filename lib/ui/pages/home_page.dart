import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import 'speak_the_canvas_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'home',
    segments: <String>['home'],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const InlineTextWidget('Taller 1'),
            subtitle: const ParagraphTextWidget(
              'Explicación del canvas y que es un pixel',
            ),
            leading: const Icon(Icons.brush),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.appManager.push(SpeakTheCanvasPage.pageModel.name);
            },
          ),
        ],
      ),
    );
  }
}
