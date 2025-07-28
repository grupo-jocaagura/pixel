import 'package:jocaagura_domain/jocaagura_domain.dart';

import '../../models/model_canvas.dart';
import '../../models/model_pixel.dart';
import '../../repositories/repository_canvas.dart';

class UpsertPixelUseCase {
  const UpsertPixelUseCase(this._repo);
  final RepositoryCanvas _repo;

  Future<Either<ErrorItem, ModelCanvas>> call({
    required ModelCanvas canvas,
    required ModelPixel pixel,
  }) async {
    final String key = '${pixel.x},${pixel.y}';
    final ModelCanvas updated = canvas.copyWith(
      pixels: <String, ModelPixel>{...canvas.pixels, key: pixel},
    );
    return _repo.saveCanvas(updated);
  }
}
