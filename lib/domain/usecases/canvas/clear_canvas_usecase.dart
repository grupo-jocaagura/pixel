import 'package:jocaagura_domain/jocaagura_domain.dart';

import '../../models/model_canvas.dart';
import '../../models/model_pixel.dart';
import '../../repositories/repository_canvas.dart';

class ClearCanvasUseCase {
  const ClearCanvasUseCase(this._repo);
  final RepositoryCanvas _repo;

  Future<Either<ErrorItem, ModelCanvas>> call(ModelCanvas canvas) async {
    final ModelCanvas cleared = canvas.copyWith(
      pixels: const <String, ModelPixel>{},
    );
    return _repo.saveCanvas(cleared);
  }
}
