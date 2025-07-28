import 'package:jocaagura_domain/jocaagura_domain.dart';

import '../models/model_canvas.dart';

/// Orquesta el Gateway y mapea a Either<ErrorItem, ModelCanvas>.
abstract class RepositoryCanvas {
  /// Loads a canvas by [id].
  /// Returns either an [ErrorItem] or the [ModelCanvas].
  Future<Either<ErrorItem, ModelCanvas>> loadCanvas(String id);

  /// Saves (creates or updates) the given [canvas].
  /// Returns either an [ErrorItem] or the saved [ModelCanvas].
  Future<Either<ErrorItem, ModelCanvas>> saveCanvas(ModelCanvas canvas);

  Stream<Either<ErrorItem, ModelCanvas>> watch(String id);

  Future<Either<ErrorItem, void>> delete(String id);
}
