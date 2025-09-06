import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../../domain/usecases/canvas/canvas_usecases.dart';
import '../../shared/util_color.dart';
import '../utils/model_vector_bridge.dart';
import '../utils/util_pixel_raster.dart';

/// BLoC encargado de la lógica de un canvas reactivo consumiendo la fachada
/// [CanvasUsecases]. Mantiene compatibilidad con el flujo actual:
/// - Estado inicial: [defaultModelCanvas]
/// - Guardado inmediato para obtener/propagar id
/// - Suscripción automática si el canvas tiene id
class BlocCanvas extends BlocModule {
  BlocCanvas({required this.usecases, required this.blocLoading}) {
    _init();
  }

  static const String name = 'blocCanvas';
  // Fachada de casos de uso
  final CanvasUsecases usecases;

  // Loading transversal
  final BlocLoading blocLoading;

  // Suscripción al documento observado
  StreamSubscription<Either<ErrorItem, ModelCanvas>>? _watchSubscription;

  // Pilas para undo/redo
  final List<ModelCanvas> _undoStack = <ModelCanvas>[];
  final List<ModelCanvas> _redoStack = <ModelCanvas>[];

  // Streams para habilitar/deshabilitar botones en la UI
  final BlocGeneral<bool> _canUndo = BlocGeneral<bool>(false);
  final BlocGeneral<bool> _canRedo = BlocGeneral<bool>(false);
  Stream<bool> get canUndoStream => _canUndo.stream;
  Stream<bool> get canRedoStream => _canRedo.stream;

  // Debounce para persistencias frecuentes (toggle grilla, resolución, etc.)
  final Debouncer _saveDebouncer = Debouncer(milliseconds: 300);

  // Estado principal: el canvas
  final BlocGeneral<ModelCanvas> _blocCanvas = BlocGeneral<ModelCanvas>(
    defaultModelCanvas,
  );
  Stream<ModelCanvas> get canvasStream => _blocCanvas.stream;
  ModelCanvas get canvas => _blocCanvas.value;

  // Errores de negocio
  final BlocGeneral<ErrorItem?> _errorBloc = BlocGeneral<ErrorItem?>(null);
  Stream<ErrorItem?> get errorStream => _errorBloc.stream;
  ErrorItem? get lastError => _errorBloc.value;

  // Loading general para todas las operaciones
  Stream<String> get loadingStream => blocLoading.loadingMsgStream;
  bool get isLoading => blocLoading.loadingMsg.isNotEmpty;

  // UI helpers
  String get resolution =>
      '${_blocCanvas.value.width}x${_blocCanvas.value.height} pixels';

  // Color seleccionado y color de líneas de grilla
  final BlocGeneral<Color> _blocColor = BlocGeneral<Color>(Colors.black);
  Color get selectedColor => _blocColor.value;
  Stream<Color> get selectedColorStream => _blocColor.stream;

  final BlocGeneral<Color> _blocGridLineColor = BlocGeneral<Color>(
    UtilColor.gridLineColor,
  );
  Color get gridLineColor => _blocGridLineColor.value;
  Stream<Color> get gridLineColorStream => _blocGridLineColor.stream;
  bool get isOn => gridLineColor != Colors.transparent;

  String get selectedHex => UtilColor.colorToHex(selectedColor);

  Future<void> _init() async {
    // Estado inicial para pruebas
    _blocCanvas.value = defaultModelCanvas;

    // Guardado inmediato: si el repo/gateway asigna id, lo obtendremos aquí
    await save();

    // Suscribirse si ya hay id válido
    final String id = _blocCanvas.value.id;
    if (id.isNotEmpty) {
      subscribeCanvas(id);
    }
  }

  /// Suscribe al stream de cambios del canvas para el [id] indicado.
  void subscribeCanvas(String id) {
    unsubscribeCanvas();
    _watchSubscription = usecases.watchCanvasUseCase.call(id).listen((
      Either<ErrorItem, ModelCanvas> either,
    ) {
      either.fold(
        (ErrorItem err) => _errorBloc.value = err,
        (ModelCanvas model) => _blocCanvas.value = model,
      );
    });
  }

  /// Cancela la suscripción activa (si existe).
  void unsubscribeCanvas() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  // ---------------------------
  // Validaciones y utilidades
  // ---------------------------

  String? validateResolutionValue(String value) {
    if (value.isEmpty) {
      return 'La resolución no puede estar vacía';
    }
    final int? resolution = int.tryParse(value);
    if (resolution == null || resolution <= 0) {
      return 'Ingrese un número válido';
    }
    return null;
  }

  void updateResolutionFromString(String value) {
    if (validateResolutionValue(value) == null) {
      final int newResolution = int.tryParse(value) ?? 0;
      updateResolution(newResolution, newResolution);
    }
  }

  void _pushStateForUndo() {
    _undoStack.add(_blocCanvas.value);
    _canUndo.value = true;
    _redoStack.clear();
    _canRedo.value = false;
  }

  // ---------------------------
  // Acciones de edición
  // ---------------------------

  void updateResolution(int width, int height) {
    if (width > 0 &&
        width != _blocCanvas.value.width &&
        height > 0 &&
        height != _blocCanvas.value.height) {
      _pushStateForUndo();
      _blocCanvas.value = _blocCanvas.value.copyWith(
        width: width,
        height: height,
      );
      _saveDebouncer(save);
    }
  }

  Future<void> undo() async {
    if (_undoStack.isEmpty) {
      return;
    }
    _redoStack.add(_blocCanvas.value);
    _canRedo.value = true;

    final ModelCanvas previous = _undoStack.removeLast();
    _blocCanvas.value = previous;
    _canUndo.value = _undoStack.isNotEmpty;

    await save();
  }

  Future<void> redo() async {
    if (_redoStack.isEmpty) {
      return;
    }
    _undoStack.add(_blocCanvas.value);
    _canUndo.value = true;

    final ModelCanvas next = _redoStack.removeLast();
    _blocCanvas.value = next;
    _canRedo.value = _redoStack.isNotEmpty;

    await save();
  }

  /// Carga un canvas existente y actualiza suscripción.
  Future<void> load(String id) async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Loading canvas...';
    final Either<ErrorItem, ModelCanvas> either = await usecases.loadUseCase
        .call(id);
    either.fold((ErrorItem err) => _errorBloc.value = err, (ModelCanvas model) {
      _blocCanvas.value = model;
      final String newId = model.id;
      if (newId.isNotEmpty) {
        subscribeCanvas(newId);
      }
    });
    blocLoading.clearLoading();
  }

  /// Guarda/actualiza el canvas completo.
  Future<void> save() async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Saving canvas...';
    final Either<ErrorItem, ModelCanvas> either = await usecases.saveUseCase
        .call(_blocCanvas.value);
    either.fold((ErrorItem err) => _errorBloc.value = err, (ModelCanvas model) {
      _blocCanvas.value = model;
      // Si el save asignó id, aseguremos la suscripción
      final String id = model.id;
      if (id.isNotEmpty) {
        subscribeCanvas(id);
      }
    });
    blocLoading.clearLoading();
  }

  /// Añade o actualiza un píxel.
  Future<void> addPixel(ModelPixel pixel) async {
    _pushStateForUndo();
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Adding pixel...';
    final Either<ErrorItem, ModelCanvas> either = await usecases
        .upsertPixelUseCase
        .call(canvas: _blocCanvas.value, pixel: pixel);
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  /// Elimina un píxel.
  Future<void> removePixel(ModelPixel pixel) async {
    _pushStateForUndo();
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Removing pixel...';
    final Either<ErrorItem, ModelCanvas> either = await usecases
        .removePixelUseCase
        .call(canvas: _blocCanvas.value, position: pixel.vector);
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  /// Limpia todos los píxeles del canvas.
  Future<void> clear() async {
    _pushStateForUndo();
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Clearing canvas...';
    final Either<ErrorItem, ModelCanvas> either = await usecases
        .clearCanvasUseCase
        .call(_blocCanvas.value);
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  /// Operaciones en lote
  Future<void> batchAddPixels(List<ModelPixel> pixels) async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Applying pixels…';
    final Either<ErrorItem, ModelCanvas> either = await usecases
        .batchUpsertPixelsUseCase
        .call(canvas: _blocCanvas.value, pixels: pixels);
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  Future<void> batchRemovePixels(List<ModelVector> positions) async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Removing pixels…';
    final Either<ErrorItem, ModelCanvas> either = await usecases
        .batchRemovePixelsUseCase
        .call(canvas: _blocCanvas.value, positions: positions);
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  /// Alterna el color activo.
  void updateSelectedColor(Color color) {
    if (color != _blocColor.value) {
      _blocColor.value = color;
    }
  }

  /// Alterna la visibilidad de las líneas de grilla (se persiste con debounce).
  void toggleGridLineColor() {
    _blocGridLineColor.value = isOn
        ? Colors.transparent
        : UtilColor.gridLineColor;
    _saveDebouncer(save);
  }

  /// Manejo de taps en el lienzo (invoca upsert/remove según exista la clave).
  void handleTapDown(TapDownDetails details, Size size) {
    final double cellSize = size.width / canvas.width;
    final int x = (details.localPosition.dx / cellSize).floor();
    final int y = (details.localPosition.dy / cellSize).floor();

    final String newHex = UtilColor.colorToHex(selectedColor);

    final ModelPixel newPixel = ModelPixel.fromCoord(x, y, hexColor: newHex);

    final ModelPixel? existing = canvas.pixels[newPixel.keyForCanvas];

    if (existing != null) {
      if (existing.hexColor.toUpperCase() == newHex.toUpperCase()) {
        removePixel(existing);
      } else {
        addPixel(newPixel);
      }
    } else {
      addPixel(newPixel);
    }
  }

  /// Funciones de dibujo
  /// Adds a line to the pixel-art canvas by rasterizing origin→destiny.
  void drawLine(
    ModelPixel origin,
    ModelPixel destiny, {
    String? hexColor,
    bool overwrite = true,
  }) {
    _pushStateForUndo();
    final String? normalized = (hexColor == null)
        ? null
        : UtilColor.normalizeHex(hexColor);
    _blocCanvas.value = UtilPixelRaster.drawLine(
      canvas: canvas,
      origin: origin,
      destiny: destiny,
      hexColorOverride: normalized,
      overwrite: overwrite,
    );
    _saveDebouncer(save);
  }

  /// Draws a rectangle defined by two opposite corners.
  /// When [fill] is true, the rectangle is filled. Otherwise, a border is drawn
  /// with [stroke] logical pixels thickness.
  void drawRectCorners(
    ModelPixel p1,
    ModelPixel p2, {
    String? hexColor,
    bool fill = false,
    int stroke = 1,
    bool overwrite = true,
  }) {
    _pushStateForUndo();
    _blocCanvas.value = UtilPixelRaster.drawRect(
      canvas: canvas,
      p1: p1,
      p2: p2,
      hexColorOverride: hexColor ?? selectedHex,
      fill: fill,
      stroke: stroke,
      overwrite: overwrite,
    );
    _saveDebouncer(save);
  }

  /// Draws a circle given center and edge (radius inferred from distance).
  void drawCircleFromTwoPoints(
    ModelPixel center,
    ModelPixel edge, {
    bool fill = false,
    int stroke = 1,
    bool overwrite = true,
  }) {
    _pushStateForUndo();
    _blocCanvas.value = UtilPixelRaster.drawCircle(
      canvas: canvas,
      center: defaultModelVector.fromXY(center.x, center.y),
      radius: sqrt(
        pow(edge.x - center.x, 2) + pow(edge.y - center.y, 2),
      ).round(),
      hexColor: UtilColor.normalizeHex(center.hexColor),
      fill: fill,
      stroke: stroke,
      overwrite: overwrite,
    );
    _saveDebouncer(save);
  }

  /// Draws an oval (ellipse) from opposite corners.
  void drawOvalCorners(
    ModelPixel p1,
    ModelPixel p2, {
    bool fill = false,
    int stroke = 1,
    bool overwrite = true,
  }) {
    _pushStateForUndo();
    _blocCanvas.value = UtilPixelRaster.drawOvalCorners(
      canvas: canvas,
      p1: defaultModelVector.fromXY(p1.x, p1.y),
      p2: defaultModelVector.fromXY(p2.x, p2.y),
      hexColor: UtilColor.normalizeHex(p1.hexColor),
      fill: fill,
      stroke: stroke,
      overwrite: overwrite,
    );
    _saveDebouncer(save);
  }

  @override
  void dispose() {
    _watchSubscription?.cancel();
    _blocCanvas.dispose();
    _blocColor.dispose();
    _blocGridLineColor.dispose();
    _errorBloc.dispose();
    blocLoading.dispose();
    _canUndo.dispose();
    _canRedo.dispose();
  }
}
