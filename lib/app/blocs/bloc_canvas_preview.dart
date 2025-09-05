import 'dart:math';

import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../../domain/states/state_preview.dart';
import '../utils/util_pixel_raster.dart';
import 'bloc_canvas.dart';

/// Bloc that centralizes transient draw intent and preview computation.
///
/// Pages become Stateless and subscribe to [stateStream].
/// UI interactions call setters here; the bloc recomputes preview pixels and
/// the painter simply renders them.
///
/// ### Example
/// ```dart
/// final preview = context.appManager.requireModuleByKey<BlocCanvasPreview>(
///   BlocCanvasPreview.name,
/// );
/// // In UI:
/// preview.setTool(DrawTool.rect, canvas, hex);
/// preview.setOrigin(Point(2,3), canvas, hex);
/// preview.setDestiny(Point(12,10), canvas, hex);
/// // Apply:
/// preview.apply(canvasBloc);
/// ```
class BlocCanvasPreview extends BlocModule {
  BlocCanvasPreview();

  static const String name = 'blocCanvasPreview';

  final BlocGeneral<StatePreview> _state = BlocGeneral<StatePreview>(
    StatePreview.initial,
  );

  Stream<StatePreview> get stateStream => _state.stream;
  StatePreview get state => _state.value;

  // -----------------------------
  // Public API (all recompute)
  // -----------------------------

  void setTool(DrawTool tool, ModelCanvas canvas, String hex) {
    _emit(state.copyWith(tool: tool, previewPixels: <ModelPixel>[]));
    _recompute(canvas, hex);
  }

  void setShowCoords(bool show, ModelCanvas canvas, String hex) {
    _emit(state.copyWith(showCoords: show));
    _recompute(canvas, hex);
  }

  void setFill(bool fill, ModelCanvas canvas, String hex) {
    _emit(state.copyWith(fill: fill));
    _recompute(canvas, hex);
  }

  void setStroke(int stroke, ModelCanvas canvas, String hex) {
    final int s = stroke < 1 ? 1 : stroke;
    _emit(state.copyWith(stroke: s));
    _recompute(canvas, hex);
  }

  void clearSelection(ModelCanvas canvas, String hex) {
    _emit(
      state.copyWith(
        clearOrigin: true,
        clearDestiny: true,
        previewPixels: <ModelPixel>[],
      ),
    );
    // preview vacío ya emitido
  }

  void setOrigin(Point<int>? p, ModelCanvas canvas, String hex) {
    _emit(state.copyWith(origin: p));
    _recompute(canvas, hex);
  }

  void setDestiny(Point<int>? p, ModelCanvas canvas, String hex) {
    _emit(state.copyWith(destiny: p));
    _recompute(canvas, hex);
  }

  /// Convenience for tap: first sets origin, then destiny, then cycles.
  void tapCell(Point<int> cell, ModelCanvas canvas, String hex) {
    if (state.origin == null) {
      setOrigin(cell, canvas, hex);
    } else if (state.destiny == null) {
      setDestiny(cell, canvas, hex);
    } else {
      _emit(state.copyWith(origin: cell, clearDestiny: true));
      _recompute(canvas, hex);
    }
  }

  // -----------------------------
  // Internals
  // -----------------------------
  void _emit(StatePreview s) {
    if (s != state) {
      _state.value = s;
    }
  }

  // app/blocs/bloc_canvas_preview.dart (añade casos al switch)

  void _recompute(ModelCanvas canvas, String hex) {
    if (!state.hasSelection) {
      _emit(state.copyWith(previewPixels: <ModelPixel>[]));
      return;
    }

    List<ModelPixel> pixels = <ModelPixel>[];
    switch (state.tool) {
      case DrawTool.line:
        pixels = UtilPixelRaster.rasterLinePixels(
          canvas: canvas,
          origin: ModelPixel.fromCoord(
            state.origin!.x,
            state.origin!.y,
            hexColor: hex,
          ),
          destiny: ModelPixel.fromCoord(
            state.destiny!.x,
            state.destiny!.y,
            hexColor: hex,
          ),
        );
        break;

      case DrawTool.rect:
        pixels = UtilPixelRaster.rasterRectPixels(
          canvas: canvas,
          p1: ModelPixel.fromCoord(
            state.origin!.x,
            state.origin!.y,
            hexColor: hex,
          ),
          p2: ModelPixel.fromCoord(
            state.destiny!.x,
            state.destiny!.y,
            hexColor: hex,
          ),
          hexColor: hex,
          fill: state.fill,
          stroke: state.stroke,
        );
        break;

      case DrawTool.circle:
        pixels = UtilPixelRaster.rasterCirclePixels(
          canvas: canvas,
          center: Point<int>(state.origin!.x, state.origin!.y),
          edge: Point<int>(state.destiny!.x, state.destiny!.y),
          hexColor: hex,
          fill: state.fill,
          stroke: state.stroke,
        );
        break;

      case DrawTool.oval:
        pixels = UtilPixelRaster.rasterOvalPixels(
          canvas: canvas,
          p1: Point<int>(state.origin!.x, state.origin!.y),
          p2: Point<int>(state.destiny!.x, state.destiny!.y),
          hexColor: hex,
          fill: state.fill,
          stroke: state.stroke,
        );
        break;
    }
    _emit(state.copyWith(previewPixels: pixels));
  }

  void apply(BlocCanvas canvasBloc) {
    if (!state.hasSelection) {
      return;
    }
    final String hex = canvasBloc.selectedHex;

    switch (state.tool) {
      case DrawTool.line:
        canvasBloc.drawLine(
          ModelPixel.fromCoord(state.origin!.x, state.origin!.y, hexColor: hex),
          ModelPixel.fromCoord(
            state.destiny!.x,
            state.destiny!.y,
            hexColor: hex,
          ),
        );
        break;

      case DrawTool.rect:
        canvasBloc.drawRectCorners(
          ModelPixel.fromCoord(state.origin!.x, state.origin!.y, hexColor: hex),
          ModelPixel.fromCoord(
            state.destiny!.x,
            state.destiny!.y,
            hexColor: hex,
          ),
          fill: state.fill,
          stroke: state.stroke,
        );
        break;

      case DrawTool.circle:
        canvasBloc.drawCircleFromTwoPoints(
          ModelPixel.fromCoord(state.origin!.x, state.origin!.y, hexColor: hex),
          ModelPixel.fromCoord(
            state.destiny!.x,
            state.destiny!.y,
            hexColor: hex,
          ),
          fill: state.fill,
          stroke: state.stroke,
        );
        break;

      case DrawTool.oval:
        canvasBloc.drawOvalCorners(
          ModelPixel.fromCoord(state.origin!.x, state.origin!.y, hexColor: hex),
          ModelPixel.fromCoord(
            state.destiny!.x,
            state.destiny!.y,
            hexColor: hex,
          ),
          fill: state.fill,
          stroke: state.stroke,
        );
        break;
    }

    // Limpia selección y preview
    _emit(
      state.copyWith(
        clearOrigin: true,
        clearDestiny: true,
        previewPixels: <ModelPixel>[],
      ),
    );
  }

  @override
  void dispose() {
    _state.dispose();
  }
}
