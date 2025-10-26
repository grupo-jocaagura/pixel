import 'package:flutter/material.dart';

import '../../app/env.dart';
import '../pages/legal/terms_and_conditions_page.dart';
import '../pages/legal/terms_and_conditions_prod_page.dart';
import 'menu_tile_widget.dart';

class TermsMenuTileWidget extends StatelessWidget {
  const TermsMenuTileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MenuTileWidget(
      label: 'Terminos y condiciones',
      description: 'Lee los términos y condiciones para pixarra',
      page: Env.isProd
          ? TermsAndConditionsProdPage.pageModel
          : TermsAndConditionsPage.pageModel,
    );
  }
}
