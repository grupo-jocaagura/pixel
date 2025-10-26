import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../widgets/terms_menu_tile_widget.dart';
import '../home_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  static const String name = 'login';
  static const PageModel pageModel = PageModel(
    name: name,
    segments: <String>[name],
  );

  @override
  Widget build(BuildContext context) {
    final BlocSession bloc = context.appManager.requireModuleByKey(
      BlocSession.name,
    );

    return Scaffold(
      appBar: AppBar(
        leading: bloc.isAuthenticated ? null : const SizedBox(),
        title: const Text('Iniciar sesión'),
      ),
      body: Center(
        child: StreamBuilder<SessionState>(
          stream: bloc.sessionStream,

          builder: (_, __) {
            if (bloc.state is Authenticating) {
              const String label = 'Verificando Auth';
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  CircularProgressIndicator(),
                  InlineTextWidget(label),
                  TermsMenuTileWidget(),
                ],
              );
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () async {
                    final Either<ErrorItem, UserModel> result = await bloc
                        .logInWithGoogle();
                    result.fold(
                      (ErrorItem err) => ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err.description))),
                      (_) => context.appManager.pageManager.pushDistinctTop(
                        HomePage.pageModel,
                      ),
                    );
                  },
                  child: const Text('Continuar con Google'),
                ),
                const SizedBox(height: 150.0),
                const TermsMenuTileWidget(),
              ],
            );
          },
        ),
      ),
    );
  }
}
