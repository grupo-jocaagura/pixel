import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import 'privacy_policy_page.dart';
import 'terms_and_conditions_page.dart';

final List<PageDef> legalPages = <PageDef>[
  PageDef(
    model: TermsAndConditionsPage.pageModel,
    builder: (_, __) => const TermsAndConditionsPage(),
  ),
  PageDef(
    model: PrivacyPolicyPage.pageModel,
    builder: (_, __) => const PrivacyPolicyPage(),
  ),
];
