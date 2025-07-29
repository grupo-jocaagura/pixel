import 'package:jocaagura_domain/jocaagura_domain.dart';

import '../../models/model_canvas.dart';
import '../../models/model_pixel.dart';
import '../../repositories/repository_canvas.dart';

/// UseCase to atomically remove a batch of pixels by their positions.
class BatchRemovePixelsUseCase {
  const BatchRemovePixelsUseCase(this._repo);
  final RepositoryCanvas _repo;

  Future<Either<ErrorItem, ModelCanvas>> call({
    required ModelCanvas canvas,
    required List<ModelVector> positions,
  }) async {
    final Map<String, ModelPixel> updated =
        Map<String, ModelPixel>.from(canvas.pixels)..removeWhere(
          (String key, ModelPixel pixel) => positions.any(
            (ModelVector pos) =>
                pixel.vector.dx.round() == pos.dx.round() &&
                pixel.vector.dy.round() == pos.dy.round(),
          ),
        );

    final ModelCanvas newCanvas = canvas.copyWith(pixels: updated);
    return _repo.saveCanvas(newCanvas);
  }
}
