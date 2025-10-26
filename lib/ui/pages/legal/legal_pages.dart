import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import 'terms_and_conditions_page.dart';
import 'terms_and_conditions_prod_page.dart';

final List<PageDef> legalPages = <PageDef>[
  PageDef(
    model: TermsAndConditionsPage.pageModel,
    builder: (_, __) => const TermsAndConditionsPage(),
  ),
  PageDef(
    model: TermsAndConditionsProdPage.pageModel,
    builder: (_, __) => const TermsAndConditionsProdPage(),
  ),
];
