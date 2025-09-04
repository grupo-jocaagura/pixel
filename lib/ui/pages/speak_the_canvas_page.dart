import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../ui_constants.dart';
import '../widgets/back_button_widget.dart';
import '../widgets/bottom_navigation_bar_widget.dart';
import '../widgets/interactive_grid_widget.dart';

class SpeakTheCanvasPage extends StatelessWidget {
  const SpeakTheCanvasPage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'SpeakTheCanvas',
    segments: <String>['speak-the-canvas'],
  );

  @override
  Widget build(BuildContext context) {
    final BlocCanvas blocCanvas = context.appManager
        .requireModuleByKey<BlocCanvas>(BlocCanvas.name);
    final String screenResolution =
        '${MediaQuery.of(context).size.width}x${MediaQuery.of(context).size.height}';
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: UIConstants.toolAppBarHeight,
        title: Row(
          children: <Widget>[
            SizedBox(
              height: UIConstants.toolAppBarHeight,
              width: UIConstants.toolAppBarHeight,
              child: Image.asset('assets/logo.png', fit: BoxFit.fitHeight),
            ),
            Text('Pixel Canvas con Map - $screenResolution'),
          ],
        ),
        leading: const BackButtonWidget(),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: blocCanvas.clear,
          ),
        ],
      ),
      body: InteractiveGridWidget(blocCanvas: blocCanvas),
      bottomNavigationBar: BottomNavigationBarWidget(blocCanvas: blocCanvas),
    );
  }
}
