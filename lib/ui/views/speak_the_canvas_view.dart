import 'package:flutter/material.dart';

import '../../app/app_state_manager.dart';
import '../../app/blocs/bloc_canvas.dart';
import '../ui_constants.dart';
import '../widgets/bottom_navigation_bar_widget.dart';
import '../widgets/interactive_grid_widget.dart';

class SpeakTheCanvasView extends StatelessWidget {
  const SpeakTheCanvasView({super.key});

  @override
  Widget build(BuildContext context) {
    final BlocCanvas blocCanvas = AppStateManager.of(context).blocCanvas;
    final String screenResolution =
        '${MediaQuery.of(context).size.width}x${MediaQuery.of(context).size.height}';
    return Scaffold(
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
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: blocCanvas.resetCanvas,
          ),
        ],
      ),
      body: InteractiveGridWidget(blocCanvas: blocCanvas),
      bottomNavigationBar: BottomNavigationBarWidget(blocCanvas: blocCanvas),
    );
  }
}
