import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../models/model_canvas.dart';
import '../../models/model_pixel.dart';
import '../../repositories/repository_canvas.dart';

/// UseCase to atomically upsert (add/update) a batch of pixels on a [ModelCanvas].
///
/// This is ideal para operaciones como “flood fill” donde queremos aplicar
/// muchos píxeles de una sola vez, y luego persistir el canvas en un único paso.
///
/// Example:
/// ```dart
/// final useCase = BatchUpsertPixelsUseCase(repo);
/// final floodPixels = computeFloodFill( startPoint, color, currentCanvas );
///
/// final result = await useCase.call(
///   canvas: currentCanvas,
///   pixels: floodPixels,
/// );
///
/// result.fold(
///   (err)   => print('Error: $err'),
///   (canvas) => print('Canvas actualizado con ${canvas.pixels.length} píxeles'),
/// );
/// ```
class BatchUpsertPixelsUseCase {
  /// Crea la instancia inyectando el repositorio.
  const BatchUpsertPixelsUseCase(this._repo);

  /// Repositorio para guardar el canvas.
  final RepositoryCanvas _repo;

  /// Aplica la lista de [pixels] sobre el [canvas] y persiste el resultado.
  ///
  /// Devuelve un [Either] con [ErrorItem] o el [ModelCanvas] actualizado.
  Future<Either<ErrorItem, ModelCanvas>> call({
    required ModelCanvas canvas,
    required List<ModelPixel> pixels,
  }) async {
    // Copiamos el mapa existente
    final Map<String, ModelPixel> updated =
        Map<String, ModelPixel>.from(canvas.pixels)..addEntries(
          pixels.map(
            (ModelPixel pixel) =>
                MapEntry<String, ModelPixel>(pixel.keyForCanvas, pixel),
          ),
        );

    final ModelCanvas newCanvas = canvas.copyWith(pixels: updated);

    return _repo.saveCanvas(newCanvas);
  }
}
