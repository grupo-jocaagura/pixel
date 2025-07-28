import 'package:flutter/material.dart';
import 'package:text_responsive/text_responsive.dart';

import '../navigation/app_route.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

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
              Navigator.pushNamed(context, AppRoute.speakTheCanvas.path);
            },
          ),
        ],
      ),
    );
  }
}
