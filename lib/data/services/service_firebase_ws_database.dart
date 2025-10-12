import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

/// Implementación real de ServiceWsDatabase sobre **Cloud Firestore**.
///
/// Paridad con FakeServiceWsDatabase:
/// - `readDocument` → `{}` si no existe (NO throw).
/// - `documentStream`/`collectionStream` → emiten `{}`/`[]` si no existe/no hay docs.
/// - `emitInitial`, `deepCopies`, `dedupeByContent`, `orderCollectionsByKey`.
/// - Coordinación con `snapshotsInSync()` para estabilidad.
///
/// Multi-tenant:
/// - Internamente mapea `collection` público a `users/{uid}/{collectionPrivado}`.
///
/// Manejo de errores en streams:
/// - `streamErrorsAsErrorItemJson`: si `true`, convierte excepciones frecuentes
///   a `Map<String, dynamic>` con el shape de `ErrorItem.toJson()`.
class ServiceFirebaseWsDatabase
    implements ServiceWsDatabase<Map<String, dynamic>> {
  ServiceFirebaseWsDatabase({
    FirebaseFirestore? firestore,
    fb.FirebaseAuth? auth,
    this.userRootCollection = 'users',
    WsDbConfig config = defaultWsDbConfig,
    this.streamErrorsAsErrorItemJson = true,
  }) : _fs = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? fb.FirebaseAuth.instance,
       _config = config;

  final FirebaseFirestore _fs;
  final fb.FirebaseAuth _auth;
  final String userRootCollection;
  final WsDbConfig _config;

  /// Si `true`, errores en streams se entregan como `ErrorItem.toJson()`.
  /// Si `false`, se propaga la excepción cruda.
  final bool streamErrorsAsErrorItemJson;

  bool _disposed = false;
  final Set<StreamSubscription<Object?>> _subs =
      <StreamSubscription<Object?>>{};

  // ---------------------------------------------------------------------------
  // Infra helpers
  // ---------------------------------------------------------------------------

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('ServiceFirebaseWsDatabase has been disposed');
    }
  }

  String _requireUid() {
    final fb.User? u = _auth.currentUser;
    if (u == null) {
      throw StateError('No active session (uid required)');
    }
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> _collectionRef(String collection) {
    if (collection.isEmpty) {
      throw ArgumentError('collection must not be empty');
    }
    final String uid = _requireUid();
    return _fs
        .collection(userRootCollection)
        .doc(uid)
        .collection(collection)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (DocumentSnapshot<Map<String, dynamic>> snap, _) =>
              snap.data() ?? <String, dynamic>{},
          toFirestore: (Map<String, dynamic> data, _) => data,
        );
  }

  DocumentReference<Map<String, dynamic>> _docRef(
    String collection,
    String docId,
  ) {
    if (docId.isEmpty) {
      throw ArgumentError('docId must not be empty');
    }
    return _collectionRef(collection).doc(docId);
  }

  // ---------------------------------------------------------------------------
  // ServiceWsDatabase API
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> document,
  }) async {
    _ensureNotDisposed();
    final DocumentReference<Map<String, dynamic>> ref = _docRef(
      collection,
      docId,
    );

    final Map<String, dynamic> safe = _config.deepCopies
        ? _deepCopyMap(document)
        : document;

    // Set replace para paridad con el fake (documento completo).
    await ref.set(safe, SetOptions(merge: false));
  }

  @override
  Future<Map<String, dynamic>> readDocument({
    required String collection,
    required String docId,
  }) async {
    _ensureNotDisposed();
    final DocumentSnapshot<Map<String, dynamic>> snap = await _docRef(
      collection,
      docId,
    ).get(const GetOptions());

    // Paridad con fake: si no existe → {}
    if (!snap.exists) {
      return <String, dynamic>{};
    }

    final Map<String, dynamic> data = Utils.mapFromDynamic(snap.data());
    return _config.deepCopies ? _deepCopyMap(data) : data;
  }

  @override
  Stream<Map<String, dynamic>> documentStream({
    required String collection,
    required String docId,
  }) {
    _ensureNotDisposed();

    final DocumentReference<Map<String, dynamic>> ref = _docRef(
      collection,
      docId,
    );

    Map<String, dynamic>? last; // para dedupe por contenido
    final StreamController<Map<String, dynamic>> ctrl =
        StreamController<Map<String, dynamic>>.broadcast();

    // 1) stream del documento
    final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> subDoc =
        ref.snapshots().listen(
          (DocumentSnapshot<Map<String, dynamic>> snap) {
            Map<String, dynamic> out = Utils.mapFromDynamic(
              snap.data() ?? <String, dynamic>{},
            );
            if (_config.deepCopies) {
              out = _deepCopyMap(out);
            }

            if (_config.dedupeByContent) {
              if (last != null && _deepEqualsMap(last!, out)) {
                return;
              }
              last = _deepCopyMap(out);
            }
            if (!ctrl.isClosed) {
              ctrl.add(out);
            }
          },
          onError: (Object e, StackTrace s) {
            _pipeErrorToStream(ctrl, e, s);
          },
        );

    _subs.add(subDoc);

    // 2) sincronizador global (evita flicker en ráfagas)
    final StreamSubscription<Object?> subSync = _fs.snapshotsInSync().listen(
      (_) {},
      onError: (Object e, StackTrace s) {
        _pipeErrorToStream(ctrl, e, s);
      },
    );
    _subs.add(subSync);

    // 3) seed inicial (emitInitial)
    if (_config.emitInitial) {
      ref
          .get()
          .then((DocumentSnapshot<Map<String, dynamic>> snap) {
            Map<String, dynamic> out = Utils.mapFromDynamic(
              snap.data() ?? <String, dynamic>{},
            );
            if (_config.deepCopies) {
              out = _deepCopyMap(out);
            }

            if (_config.dedupeByContent) {
              if (last != null && _deepEqualsMap(last!, out)) {
                return;
              }
              last = _deepCopyMap(out);
            }
            if (!ctrl.isClosed) {
              ctrl.add(out);
            }
          })
          .catchError((Object e, StackTrace s) {
            _pipeErrorToStream(ctrl, e, s);
          });
    }

    ctrl.onCancel = () async {
      await subDoc.cancel();
      await subSync.cancel();
    };

    return ctrl.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> collectionStream({
    required String collection,
  }) {
    _ensureNotDisposed();

    final CollectionReference<Map<String, dynamic>> col = _collectionRef(
      collection,
    );

    List<Map<String, dynamic>>? last;

    return Stream<List<Map<String, dynamic>>>.multi((
      StreamController<List<Map<String, dynamic>>> ctrl,
    ) {
      final StreamSubscription<QuerySnapshot<Map<String, dynamic>>> sub = col
          .snapshots()
          .listen(
            (QuerySnapshot<Map<String, dynamic>> qs) {
              final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = qs
                  .docs
                  .toList();

              // Orden determinista (por id) si la config lo exige.
              if (_config.orderCollectionsByKey) {
                docs.sort(
                  (
                    QueryDocumentSnapshot<Map<String, dynamic>> a,
                    QueryDocumentSnapshot<Map<String, dynamic>> b,
                  ) => a.id.compareTo(b.id),
                );
              }

              final List<Map<String, dynamic>> list = <Map<String, dynamic>>[
                for (final QueryDocumentSnapshot<Map<String, dynamic>> d
                    in docs)
                  _config.deepCopies
                      ? _deepCopyMap(Utils.mapFromDynamic(d.data()))
                      : Utils.mapFromDynamic(d.data()),
              ];

              if (_config.dedupeByContent) {
                if (last != null && _deepEqualsList(last!, list)) {
                  return;
                }
                last = _deepCopyList(list);
              }

              if (!ctrl.isClosed) {
                ctrl.add(list);
              }
            },
            onError: (Object e, StackTrace s) {
              _pipeErrorToStream(ctrl, e, s);
            },
          );

      _subs.add(sub);

      // Seed inicial
      if (_config.emitInitial) {
        col
            .get()
            .then((QuerySnapshot<Map<String, dynamic>> qs) {
              final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = qs
                  .docs
                  .toList();

              if (_config.orderCollectionsByKey) {
                docs.sort(
                  (
                    QueryDocumentSnapshot<Map<String, dynamic>> a,
                    QueryDocumentSnapshot<Map<String, dynamic>> b,
                  ) => a.id.compareTo(b.id),
                );
              }

              final List<Map<String, dynamic>> list = <Map<String, dynamic>>[
                for (final QueryDocumentSnapshot<Map<String, dynamic>> d
                    in docs)
                  _config.deepCopies
                      ? _deepCopyMap(Utils.mapFromDynamic(d.data()))
                      : Utils.mapFromDynamic(d.data()),
              ];

              if (_config.dedupeByContent) {
                if (last != null && _deepEqualsList(last!, list)) {
                  return;
                }
                last = _deepCopyList(list);
              }

              if (!ctrl.isClosed) {
                ctrl.add(list);
              }
            })
            .catchError((Object e, StackTrace s) {
              _pipeErrorToStream(ctrl, e, s);
            });
      }

      ctrl.onCancel = () => sub.cancel();
    });
  }

  @override
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    _ensureNotDisposed();
    // Idempotente: si no existe, no falla.
    await _docRef(collection, docId).delete();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    for (final StreamSubscription<Object?> s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
    _disposed = true;
  }

  // ---------------------------------------------------------------------------
  // Error mapper (→ ErrorItem JSON) para streams
  // ---------------------------------------------------------------------------

  void _pipeErrorToStream<T>(
    StreamController<T> ctrl,
    Object error,
    StackTrace s,
  ) {
    if (!streamErrorsAsErrorItemJson) {
      if (!ctrl.isClosed) {
        ctrl.addError(error, s);
      }
      return;
    }

    final Map<String, dynamic> mapped = _mapErrorToErrorItemJson(error);
    if (!ctrl.isClosed) {
      ctrl.addError(mapped, s);
    }
  }

  Map<String, dynamic> _mapErrorToErrorItemJson(Object error) {
    // Defaults
    String title = 'Unknown Error';
    String code = 'ERR_UNKNOWN';
    String description = 'An unspecified error has occurred.';
    ErrorLevelEnum level = ErrorLevelEnum.systemInfo;
    final Map<String, dynamic> meta = <String, dynamic>{};

    if (error is FirebaseException) {
      // Códigos comunes de Firestore
      switch (error.code) {
        case 'permission-denied':
          title = 'Permission denied';
          code = 'ERR_PERMISSION_DENIED';
          description = 'You do not have access to this resource.';
          level = ErrorLevelEnum.severe;
          break;
        case 'not-found':
          title = 'Document not found';
          code = 'ERR_DOCUMENT_NOT_FOUND';
          description = 'The requested document does not exist.';
          level = ErrorLevelEnum.warning;
          break;
        case 'unavailable':
          title = 'Service unavailable';
          code = 'ERR_UNAVAILABLE';
          description = 'Firestore service is temporarily unavailable.';
          level = ErrorLevelEnum.warning;
          break;
        case 'deadline-exceeded':
          title = 'Timeout';
          code = 'ERR_TIMEOUT';
          description = 'The request took too long to complete.';
          level = ErrorLevelEnum.warning;
          break;
        case 'aborted':
          title = 'Operation aborted';
          code = 'ERR_ABORTED';
          description = 'The operation was aborted, please retry.';
          level = ErrorLevelEnum.warning;
          break;
        case 'already-exists':
          title = 'Already exists';
          code = 'ERR_ALREADY_EXISTS';
          description = 'The document already exists.';
          level = ErrorLevelEnum.systemInfo;
          break;
        default:
          title = 'Firestore error';
          code = 'ERR_FIRESTORE_${error.code.toUpperCase()}';
          description = error.message ?? 'Unknown Firestore error';
          level = ErrorLevelEnum.systemInfo;
      }
      meta['plugin'] = error.plugin;
      meta['code'] = error.code;
      meta['message'] = error.message;
    } else if (error is StateError) {
      title = 'State error';
      code = 'ERR_STATE';
      description = error.message;
      level = ErrorLevelEnum.severe;
    } else if (error is ArgumentError) {
      final String tmpDescription = Utils.getStringFromDynamic(error.message);
      title = 'Invalid argument';
      code = 'ERR_ARGUMENT';
      description = tmpDescription.isEmpty
          ? 'Invalid parameter'
          : tmpDescription;
      level = ErrorLevelEnum.warning;
    } else if (error is TimeoutException) {
      title = 'Timeout';
      code = 'ERR_TIMEOUT';
      description = error.message ?? 'The request timed out.';
      level = ErrorLevelEnum.warning;
      meta['duration'] = error.duration?.inMilliseconds;
    } else {
      meta['type'] = error.runtimeType.toString();
      meta['toString'] = error.toString();
    }

    return <String, dynamic>{
      ErrorItemEnum.title.name: title,
      ErrorItemEnum.code.name: code,
      ErrorItemEnum.description.name: description,
      ErrorItemEnum.meta.name: meta,
      ErrorItemEnum.errorLevel.name: level.name,
    };
  }

  // ---------------------------------------------------------------------------
  // Deep copy / equals (paridad con fake)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> src) {
    final Map<String, dynamic> out = <String, dynamic>{};
    src.forEach((String k, dynamic v) => out[k] = _deepCopyDynamic(v));
    return out;
  }

  List<Map<String, dynamic>> _deepCopyList(List<Map<String, dynamic>> src) =>
      <Map<String, dynamic>>[
        for (final Map<String, dynamic> m in src) _deepCopyMap(m),
      ];

  dynamic _deepCopyDynamic(dynamic v) {
    if (v is Map) {
      return _deepCopyMap(Utils.mapFromDynamic(v));
    }
    if (v is List) {
      return <dynamic>[for (final dynamic x in v) _deepCopyDynamic(x)];
    }
    return v;
  }

  bool _deepEqualsMap(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (final String k in a.keys) {
      if (!b.containsKey(k)) {
        return false;
      }
      if (!_deepEqualsDynamic(a[k], b[k])) {
        return false;
      }
    }
    return true;
  }

  bool _deepEqualsList(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (!_deepEqualsMap(a[i], b[i])) {
        return false;
      }
    }
    return true;
  }

  bool _deepEqualsDynamic(dynamic a, dynamic b) {
    if (identical(a, b)) {
      return true;
    }
    if (a is Map && b is Map) {
      return _deepEqualsMap(Utils.mapFromDynamic(a), Utils.mapFromDynamic(b));
    }
    if (a is List && b is List) {
      if (a.length != b.length) {
        return false;
      }
      for (int i = 0; i < a.length; i++) {
        if (!_deepEqualsDynamic(a[i], b[i])) {
          return false;
        }
      }
      return true;
    }
    return a == b;
  }
}
