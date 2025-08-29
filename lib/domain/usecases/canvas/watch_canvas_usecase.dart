import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../models/model_canvas.dart';
import '../../repositories/repository_canvas.dart';

/// UseCase que expone un stream reactivo de un [ModelCanvas] por su [id].
///
/// Se suscribe a los cambios del canvas y emite un [Either<ErrorItem, ModelCanvas>]
/// cada vez que hay una actualización.
class WatchCanvasUseCase {
  /// Crea el UseCase con la abstracción de repositorio.
  const WatchCanvasUseCase(this._repository);

  final RepositoryCanvas _repository;

  /// Retorna un [Stream] de resultados que puede ser un [ErrorItem] o un [ModelCanvas].
  ///
  /// Cada emisión corresponde a una actualización en tiempo real del canvas.
  Stream<Either<ErrorItem, ModelCanvas>> call(String id) {
    return _repository.watch(id);
  }
}
