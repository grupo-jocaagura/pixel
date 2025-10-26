import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import 'home_page.dart';
import 'legal/legal_pages.dart';
import 'not_found_route_page.dart';
import 'session/login_page.dart';
import 'speak_the_canvas_page.dart';
import 'speak_the_circle_page.dart';
import 'speak_the_line_page.dart';
import 'speak_the_oval_page.dart';
import 'speak_the_rect_page.dart';
import 'splash_screen_page.dart';

const List<PageModel> pages = <PageModel>[SplashScreenPage.pageModel];

final NavStackModel navStackModel = NavStackModel(pages);

final PageRegistry pageRegistry = PageRegistry.fromDefs(
  <PageDef>[
    PageDef(
      model: HomePage.pageModel,
      builder: (_, PageModel page) => const HomePage(),
    ),
    PageDef(
      model: SplashScreenPage.pageModel,
      builder: (_, PageModel page) => const SplashScreenPage(),
    ),
    PageDef(
      model: NotFoundRoutePage.pageModel,
      builder: (_, PageModel page) => const NotFoundRoutePage(),
    ),
    PageDef(
      model: SpeakTheCanvasPage.pageModel,
      builder: (_, PageModel page) => const SpeakTheCanvasPage(),
    ),
    PageDef(
      model: SpeakTheLinePage.pageModel,
      builder: (_, PageModel page) => const SpeakTheLinePage(),
    ),
    PageDef(
      model: SpeakTheRectPage.pageModel,
      builder: (_, PageModel page) => const SpeakTheRectPage(),
    ),
    PageDef(
      model: SpeakTheCirclePage.pageModel,
      builder: (_, PageModel page) => const SpeakTheCirclePage(),
    ),
    PageDef(
      model: SpeakTheOvalPage.pageModel,
      builder: (_, PageModel page) => const SpeakTheOvalPage(),
    ),
    PageDef(
      model: LoginPage.pageModel,
      builder: (_, PageModel page) => const LoginPage(),
    ),
    ...legalPages,
  ],
  notFoundBuilder: (_, PageModel page) => const NotFoundRoutePage(),
  defaultPage: SplashScreenPage.pageModel,
);
