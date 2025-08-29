import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../models/model_canvas.dart';
import '../../models/model_pixel.dart';
import '../../repositories/repository_canvas.dart';

/// UseCase to create a new empty canvas and persist it.
class CreateCanvasUseCase {
  const CreateCanvasUseCase(this._repo);
  final RepositoryCanvas _repo;

  Future<Either<ErrorItem, ModelCanvas>> call({
    required String id,
    required int width,
    required int height,
    required double pixelSize,
  }) async {
    final ModelCanvas canvas = ModelCanvas(
      id: id,
      width: width,
      height: height,
      pixelSize: pixelSize,
      pixels: const <String, ModelPixel>{},
    );
    return _repo.saveCanvas(canvas);
  }
}
