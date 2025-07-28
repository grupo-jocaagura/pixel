import 'package:jocaagura_domain/jocaagura_domain.dart';

import '../../models/model_canvas.dart';
import '../../models/model_pixel.dart';
import '../../repositories/repository_canvas.dart';

class RemovePixelUseCase {
  const RemovePixelUseCase(this._repo);
  final RepositoryCanvas _repo;

  Future<Either<ErrorItem, ModelCanvas>> call({
    required ModelCanvas canvas,
    required ModelVector position,
  }) async {
    final String key = '${position.dx.round()},${position.dy.round()}';
    final Map<String, ModelPixel> updatedPixels = Map<String, ModelPixel>.from(
      canvas.pixels,
    )..remove(key);
    final ModelCanvas updated = canvas.copyWith(pixels: updatedPixels);
    return _repo.saveCanvas(updated);
  }
}
