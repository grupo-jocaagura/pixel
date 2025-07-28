import 'package:jocaagura_domain/jocaagura_domain.dart';

import '../../domain/gateways/gateway_canvas.dart';
import '../../domain/models/model_canvas.dart';
import '../../domain/repositories/repository_canvas.dart';

/// Implementation of [RepositoryCanvas] using a [GatewayCanvas].
class RepositoryCanvasImpl implements RepositoryCanvas {
  RepositoryCanvasImpl(this._gateway);
  final GatewayCanvas _gateway;
  static const ErrorItem invalidSizeError = ErrorItem(
    title: 'Invalid Size',
    code: 'ERR_REPO_INVALID_SIZE',
    description: 'Canvas width and height must be greater than zero.',
    errorLevel: ErrorLevelEnum.severe,
  );
  static const ErrorItem defaultLoadError = ErrorItem(
    title: 'Load Error',
    code: 'ERR_REPO_LOAD_CANVAS',
    description: 'Failed to load canvas or canvas not found.',
    errorLevel: ErrorLevelEnum.warning,
  );

  static const ErrorItem defaultParseError = ErrorItem(
    title: 'Parse Error',
    code: 'ERR_PARSE_CANVAS',
    description: 'Unable to parse canvas JSON',
    errorLevel: ErrorLevelEnum.danger,
  );
  static const ErrorItem defaultSaveError = ErrorItem(
    title: 'Invalid Canvas ID',
    code: 'ERR_REPO_INVALID_ID',
    description: 'Canvas id must be provided to save.',
    errorLevel: ErrorLevelEnum.severe,
  );

  /// Creates a new repository that delegates to [gateway].

  @override
  Future<Either<ErrorItem, ModelCanvas>> loadCanvas(String id) async {
    final Either<ErrorItem, Map<String, dynamic>> rawResult = await _gateway
        .read(id);
    return rawResult.fold(
      (ErrorItem err) => Left<ErrorItem, ModelCanvas>(err),
      (Map<String, dynamic> json) {
        try {
          final ModelCanvas model = ModelCanvas.fromJson(json);
          return Right<ErrorItem, ModelCanvas>(model);
        } catch (e) {
          return Left<ErrorItem, ModelCanvas>(defaultParseError);
        }
      },
    );
  }

  @override
  Future<Either<ErrorItem, ModelCanvas>> saveCanvas(ModelCanvas canvas) async {
    final String? id = canvas.id;
    if (canvas.width <= 0 || canvas.height <= 0) {
      return Left<ErrorItem, ModelCanvas>(invalidSizeError);
    }
    if (id == null || id.isEmpty) {
      return Left<ErrorItem, ModelCanvas>(defaultSaveError);
    }
    final Either<ErrorItem, Map<String, dynamic>> rawResult = await _gateway
        .write(id, canvas.toJson());
    return rawResult.fold(
      (ErrorItem err) => Left<ErrorItem, ModelCanvas>(err),
      (Map<String, dynamic> json) {
        try {
          final ModelCanvas model = ModelCanvas.fromJson(json);
          return Right<ErrorItem, ModelCanvas>(model);
        } catch (e) {
          return Left<ErrorItem, ModelCanvas>(defaultParseError);
        }
      },
    );
  }

  @override
  Stream<Either<ErrorItem, ModelCanvas>> watch(String id) {
    return _gateway
        .watch(id)
        .map(
          (Either<ErrorItem, Map<String, dynamic>> eitherRaw) => eitherRaw.fold(
            (ErrorItem err) => Left<ErrorItem, ModelCanvas>(err),
            (Map<String, dynamic> json) {
              try {
                final ModelCanvas model = ModelCanvas.fromJson(json);
                return Right<ErrorItem, ModelCanvas>(model);
              } catch (e) {
                return Left<ErrorItem, ModelCanvas>(defaultParseError);
              }
            },
          ),
        );
  }

  @override
  Future<Either<ErrorItem, void>> delete(String id) async {
    return _gateway.delete(id);
  }
}
