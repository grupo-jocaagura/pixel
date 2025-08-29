import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

/// Interfaz que abstrae el acceso a la base de datos de canvas.
abstract class GatewayCanvas {
  /// Lee un documento de canvas por su [docId], devuelve el map raw o null.
  Future<Either<ErrorItem, Map<String, dynamic>>> read(String docId);

  /// Escribe (crea/actualiza) el canvas con [docId] y su representación JSON.
  Future<Either<ErrorItem, Map<String, dynamic>>> write(
    String docId,
    Map<String, dynamic> json,
  );

  Future<Either<ErrorItem, void>> delete(String docId);

  Stream<Either<ErrorItem, Map<String, dynamic>>> watch(String docId);
}
