import '../../repositories/repository_canvas.dart';
import 'batch_remove_pixels_usecase.dart';
import 'batch_upsert_pixel_usecase.dart';
import 'clear_canvas_usecase.dart';
import 'create_canvas_usecase.dart';
import 'load_canvas_usecase.dart';
import 'remove_pixel_usecase.dart';
import 'save_canvas_usecase.dart';
import 'upsert_pixel_usecase.dart';
import 'watch_canvas_usecase.dart';

/// Fachada que agrupa todos los casos de uso de Canvas
class CanvasUsecases {
  const CanvasUsecases({
    required this.createUseCase,
    required this.loadUseCase,
    required this.saveUseCase,
    required this.upsertPixelUseCase,
    required this.removePixelUseCase,
    required this.clearCanvasUseCase,
    required this.watchCanvasUseCase,
    required this.batchUpsertPixelsUseCase,
    required this.batchRemovePixelsUseCase,
  });
  factory CanvasUsecases.fromRepo(RepositoryCanvas repositoryCanvas) {
    return CanvasUsecases(
      createUseCase: CreateCanvasUseCase(repositoryCanvas),
      loadUseCase: LoadCanvasUseCase(repositoryCanvas),
      saveUseCase: SaveCanvasUseCase(repositoryCanvas),
      upsertPixelUseCase: UpsertPixelUseCase(repositoryCanvas),
      removePixelUseCase: RemovePixelUseCase(repositoryCanvas),
      clearCanvasUseCase: ClearCanvasUseCase(repositoryCanvas),
      watchCanvasUseCase: WatchCanvasUseCase(repositoryCanvas),
      batchRemovePixelsUseCase: BatchRemovePixelsUseCase(repositoryCanvas),
      batchUpsertPixelsUseCase: BatchUpsertPixelsUseCase(repositoryCanvas),
    );
  }
  final CreateCanvasUseCase createUseCase;
  final LoadCanvasUseCase loadUseCase;
  final SaveCanvasUseCase saveUseCase;
  final UpsertPixelUseCase upsertPixelUseCase;
  final RemovePixelUseCase removePixelUseCase;
  final ClearCanvasUseCase clearCanvasUseCase;
  final WatchCanvasUseCase watchCanvasUseCase;
  final BatchUpsertPixelsUseCase batchUpsertPixelsUseCase;
  final BatchRemovePixelsUseCase batchRemovePixelsUseCase;
}
