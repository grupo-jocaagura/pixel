import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../widgets/menu_tile_widget.dart';
import '../widgets/terms_menu_tile_widget.dart';
import 'session/login_page.dart';
import 'speak_the_canvas_page.dart';
import 'speak_the_circle_page.dart';
import 'speak_the_line_page.dart';
import 'speak_the_oval_page.dart';
import 'speak_the_rect_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'home',
    segments: <String>['home'],
  );

  @override
  Widget build(BuildContext context) {
    final BlocSession blocSession = context.appManager
        .requireModuleByKey<BlocSession>(BlocSession.name);

    return StreamBuilder<SessionState>(
      stream: blocSession.sessionStream,
      builder: (_, __) {
        if (blocSession.isAuthenticated) {
          return Scaffold(
            body: ListView(
              children: <Widget>[
                const MenuTileWidget(
                  label: 'Taller 1',
                  description: 'Explicación del canvas y que es un pixel',
                  page: SpeakTheCanvasPage.pageModel,
                ),
                const MenuTileWidget(
                  label: 'Taller 2',
                  description: 'Explicación de la linea',
                  page: SpeakTheLinePage.pageModel,
                ),
                const MenuTileWidget(
                  label: 'Taller 2',
                  description: 'Explicación del Rectangulo',
                  page: SpeakTheRectPage.pageModel,
                ),
                const MenuTileWidget(
                  label: 'Taller 2',
                  description: 'Explicación del Circulo',
                  page: SpeakTheCirclePage.pageModel,
                ),
                const MenuTileWidget(
                  label: 'Taller 2',
                  description: 'Explicación del Ovalo',
                  page: SpeakTheOvalPage.pageModel,
                ),
                ListTile(
                  title: const InlineTextWidget('Cerrar sesion'),
                  onTap: () {
                    blocSession.logOut();
                  },
                ),

                const TermsMenuTileWidget(),
              ],
            ),
          );
        }
        return const LoginPage();
      },
    );
  }
}
