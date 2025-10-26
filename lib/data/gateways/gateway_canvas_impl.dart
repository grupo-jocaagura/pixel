import 'dart:async';

import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../domain/gateways/gateway_canvas.dart';

/// Implementación reactiva del gateway.
class GatewayCanvasImpl implements GatewayCanvas {
  GatewayCanvasImpl(this._db);
  static const Duration delay = Duration(milliseconds: 100);
  static const ErrorItem defaultError = ErrorItem(
    title: 'Document not found',
    code: 'ERR_DOCUMENTNOTFOUND',
    description: 'The document is not present at database.',
  );
  static const ErrorItem defaultDeleteError = ErrorItem(
    title: 'Delete Error',
    code: 'ERR_DELETE',
    description: 'Failed to delete document',
  );
  static const ErrorItem defaultWriteError = ErrorItem(
    title: 'Write Error',
    code: 'ERR_WRITE',
    description: 'Failed to write document',
  );
  static const String collection = 'canvas';

  final ServiceWsDb _db;

  @override
  Future<Either<ErrorItem, Map<String, dynamic>>> read(String docId) async {
    await _db.readDocument(collection: collection, docId: docId);
    return _getDocument(docId);
  }

  Future<Either<ErrorItem, Map<String, dynamic>>> _getDocument(
    String docId,
  ) async {
    final Map<String, dynamic> document = await _db.readDocument(
      collection: collection,
      docId: docId,
    );
    if (document.isEmpty) {
      return Left<ErrorItem, Map<String, dynamic>>(defaultError);
    }
    return Right<ErrorItem, Map<String, dynamic>>(document);
  }

  @override
  Future<Either<ErrorItem, Map<String, dynamic>>> write(
    String docId,
    Map<String, dynamic> json,
  ) async {
    return _withLock(docId, () async {
      await _db.saveDocument(
        collection: collection,
        docId: docId,
        document: json,
      );
      return _getDocument(docId);
    });
  }

  @override
  Future<Either<ErrorItem, void>> delete(String docId) async {
    return _withLock(docId, () async {
      await _db.deleteDocument(collection: collection, docId: docId);
      final Map<String, dynamic> document = await _db.readDocument(
        collection: collection,
        docId: docId,
      );

      return document.isEmpty
          ? Right<ErrorItem, void>(null)
          : Left<ErrorItem, void>(defaultDeleteError);
    });
  }

  @override
  Stream<Either<ErrorItem, Map<String, dynamic>>> watch(String docId) {
    return _db
        .documentStream(collection: collection, docId: docId)
        .map<Either<ErrorItem, Map<String, dynamic>>>(
          (Map<String, dynamic> data) =>
              Right<ErrorItem, Map<String, dynamic>>(data),
        )
        .handleError(
          (_) => Left<ErrorItem, Map<String, dynamic>>(defaultError),
        );
  }

  final Map<String, Completer<void>> _locks = <String, Completer<void>>{};

  /// Ejecuta [action] de forma exclusiva para un [docId], encola si ya hay otro en curso.
  Future<T> _withLock<T>(String docId, Future<T> Function() action) async {
    while (_locks.containsKey(docId)) {
      await _locks[docId]!.future;
    }
    final Completer<void> completer = Completer<void>();
    _locks[docId] = completer;
    try {
      return await action();
    } finally {
      completer.complete();
      _locks.remove(docId);
    }
  }

  void dispose() {
    for (final Completer<void> completer in _locks.values) {
      completer.complete();
    }
    _locks.clear();
  }
}
