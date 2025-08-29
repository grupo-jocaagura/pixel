import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../models/model_canvas.dart';
import '../../repositories/repository_canvas.dart';

/// UseCase to save (create/update) a canvas.
class SaveCanvasUseCase {
  const SaveCanvasUseCase(this._repo);
  final RepositoryCanvas _repo;

  Future<Either<ErrorItem, ModelCanvas>> call(ModelCanvas canvas) async {
    return _repo.saveCanvas(canvas);
  }
}
