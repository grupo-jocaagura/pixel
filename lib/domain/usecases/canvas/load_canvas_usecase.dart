import 'package:jocaagura_domain/jocaagura_domain.dart';

import '../../models/model_canvas.dart';
import '../../repositories/repository_canvas.dart';

/// UseCase to load an existing canvas by id.
class LoadCanvasUseCase {
  const LoadCanvasUseCase(this._repo);
  final RepositoryCanvas _repo;

  Future<Either<ErrorItem, ModelCanvas>> call(String id) async {
    return _repo.loadCanvas(id);
  }
}
