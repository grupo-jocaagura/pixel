import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jocaagura_domain/jocaagura_domain.dart';

import '../../domain/models/model_canvas.dart';
import '../../domain/models/model_pixel.dart';
import '../../domain/usecases/canvas/batch_remove_pixels_usecase.dart';
import '../../domain/usecases/canvas/batch_upsert_pixel_usecase.dart';
import '../../domain/usecases/canvas/clear_canvas_usecase.dart';
import '../../domain/usecases/canvas/create_canvas_usecase.dart';
import '../../domain/usecases/canvas/load_canvas_usecase.dart';
import '../../domain/usecases/canvas/remove_pixel_usecase.dart';
import '../../domain/usecases/canvas/save_canvas_usecase.dart';
import '../../domain/usecases/canvas/upsert_pixel_usecase.dart';
import '../../domain/usecases/canvas/watch_canvas_usecase.dart';
import '../../shared/util_color.dart';
import 'bloc_loading.dart';

class BlocCanvas extends BlocModule {
  BlocCanvas({
    required this.createUseCase,
    required this.loadUseCase,
    required this.saveUseCase,
    required this.upsertPixelUseCase,
    required this.removePixelUseCase,
    required this.clearCanvasUseCase,
    required this.blocLoading,
    required this.watchCanvasUseCase,
    required this.batchRemovePixelsUseCase,
    required this.batchUpsertPixelsUseCase,
  }) {
    _init();
  }

  String get resolution =>
      '${_blocCanvas.value.width}x${_blocCanvas.value.height} pixels';
  late final StreamSubscription<Either<ErrorItem, ModelCanvas>>?
  _watchSubscription;
  // UseCases inyectados
  final CreateCanvasUseCase createUseCase;
  final LoadCanvasUseCase loadUseCase;
  final SaveCanvasUseCase saveUseCase;
  final UpsertPixelUseCase upsertPixelUseCase;
  final RemovePixelUseCase removePixelUseCase;
  final ClearCanvasUseCase clearCanvasUseCase;
  final WatchCanvasUseCase watchCanvasUseCase;
  final BlocLoading blocLoading;
  final BatchUpsertPixelsUseCase batchUpsertPixelsUseCase;
  final BatchRemovePixelsUseCase batchRemovePixelsUseCase;

  final Debouncer _saveDebouncer = Debouncer(milliseconds: 300);
  // Estado principal: el canvas
  final BlocGeneral<ModelCanvas> _blocCanvas = BlocGeneral<ModelCanvas>(
    defaultModelCanvas,
  );
  Stream<ModelCanvas> get canvasStream => _blocCanvas.stream;
  ModelCanvas get canvas => _blocCanvas.value;

  // Loading general para todas las operaciones

  Stream<String> get loadingStream => blocLoading.loadingMsgStream;
  bool get isLoading => blocLoading.loadingMsg.isNotEmpty;

  // Errores de negocio
  final BlocGeneral<ErrorItem?> _errorBloc = BlocGeneral<ErrorItem?>(null);
  Stream<ErrorItem?> get errorStream => _errorBloc.stream;
  ErrorItem? get lastError => _errorBloc.value;

  // Color y grid line color (sin cambios)
  final BlocGeneral<Color> _blocColor = BlocGeneral<Color>(Colors.black);
  Color get selectedColor => _blocColor.value;
  Stream<Color> get selectedColorStream => _blocColor.stream;

  final BlocGeneral<Color> _blocGridLineColor = BlocGeneral<Color>(
    UtilColor.gridLineColor,
  );
  Color get gridLineColor => _blocGridLineColor.value;
  Stream<Color> get gridLineColorStream => _blocGridLineColor.stream;
  bool get isOn => gridLineColor != Colors.transparent;

  // Inicialización (puede cargar un canvas existente si se quiere)
  Future<void> _init() async {
    // Por ahora no hacemos load automático
    // Si queremos, descomenta:
    // await load('some-doc-id');
    _blocCanvas.value = defaultModelCanvas;
    await save();
    // Suscribirse inicialmente con el ID por defecto
    subscribeCanvas(defaultModelCanvasId);
  }

  /// Suscribe al stream de cambios del canvas para el [id] indicado.
  /// Si ya había una suscripción previa, la cancela primero.
  void subscribeCanvas(String id) {
    unsubscribeCanvas();
    _watchSubscription = watchCanvasUseCase.call(id).listen((
      Either<ErrorItem, ModelCanvas> either,
    ) {
      either.fold(
        (ErrorItem err) => _errorBloc.value = err,
        (ModelCanvas model) => _blocCanvas.value = model,
      );
    });
  }

  /// Cancela la suscripción activa (si existe) y limpia el error relacionado.
  void unsubscribeCanvas() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  // form validation
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

  void updateResolution(int width, int height) {
    if (width > 0 &&
        width != _blocCanvas.value.width &&
        height > 0 &&
        height != _blocCanvas.value.height) {
      _blocCanvas.value = _blocCanvas.value.copyWith(
        width: width,
        height: height,
      );
      _saveDebouncer(save);
    }
  }

  /// Carga un canvas existente.
  Future<void> load(String id) async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Loading canvas...';
    final Either<ErrorItem, ModelCanvas> either = await loadUseCase.call(id);
    either.fold((ErrorItem err) => _errorBloc.value = err, (ModelCanvas model) {
      _blocCanvas.value = model;
      if (model.id.isNotEmpty) {
        subscribeCanvas(model.id);
      }
    });
    blocLoading.clearLoading();
  }

  /// Guarda/actualiza el canvas completo (por ejemplo tras cambiar resolución).
  Future<void> save() async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Saving canvas...';
    final Either<ErrorItem, ModelCanvas> either = await saveUseCase.call(
      _blocCanvas.value,
    );
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  /// Añade o actualiza un píxel usando el UseCase.
  Future<void> addPixel(ModelPixel pixel) async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Adding pixel...';
    final Either<ErrorItem, ModelCanvas> either = await upsertPixelUseCase.call(
      canvas: _blocCanvas.value,
      pixel: pixel,
    );
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  /// Elimina un píxel usando el UseCase.
  Future<void> removePixel(ModelPixel pixel) async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Removing pixel...';
    final Either<ErrorItem, ModelCanvas> either = await removePixelUseCase.call(
      canvas: _blocCanvas.value,
      position: pixel.vector,
    );
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  /// Limpia todos los píxeles.
  Future<void> clear() async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Clearing canvas...';
    final Either<ErrorItem, ModelCanvas> either = await clearCanvasUseCase.call(
      _blocCanvas.value,
    );
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  void resetCanvas() {
    clear();
  }

  /// Alterna el color activo.
  void updateSelectedColor(Color color) {
    if (color != _blocColor.value) {
      _blocColor.value = color;
    }
  }

  /// Alterna la visibilidad de las grillas.
  void toggleGridLineColor() {
    _blocGridLineColor.value = isOn
        ? Colors.transparent
        : UtilColor.gridLineColor;
    _saveDebouncer(save);
  }

  /// Manejo de taps en el lienzo (no persiste, solo local).
  void handleTapDown(TapDownDetails details, Size size) {
    final double cellSize = size.width / canvas.width;
    final int x = (details.localPosition.dx / cellSize).floor();
    final int y = (details.localPosition.dy / cellSize).floor();
    final ModelPixel pixel = ModelPixel.fromCoord(
      x,
      y,
      hexColor: UtilColor.colorToHex(selectedColor),
    );
    if (canvas.pixels.containsKey(pixel.keyForCanvas)) {
      removePixel(pixel);
    } else {
      addPixel(pixel);
    }
  }

  /// Aplica un lote de píxeles (e.g. flood fill).
  Future<void> batchAddPixels(List<ModelPixel> pixels) async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Applying pixels…';
    final Either<ErrorItem, ModelCanvas> either = await batchUpsertPixelsUseCase
        .call(canvas: _blocCanvas.value, pixels: pixels);
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  /// Elimina un lote de píxeles por posición.
  Future<void> batchRemovePixels(List<ModelVector> positions) async {
    _errorBloc.value = null;
    blocLoading.loadingMsg = 'Removing pixels…';
    final Either<ErrorItem, ModelCanvas> either = await batchRemovePixelsUseCase
        .call(canvas: _blocCanvas.value, positions: positions);
    either.fold(
      (ErrorItem err) => _errorBloc.value = err,
      (ModelCanvas model) => _blocCanvas.value = model,
    );
    blocLoading.clearLoading();
  }

  @override
  void dispose() {
    _blocCanvas.dispose();
    _blocColor.dispose();
    _blocGridLineColor.dispose();
    _errorBloc.dispose();
    blocLoading.dispose();
    _watchSubscription?.cancel();
  }
}
