import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../../app/env.dart';
import '../../../app/pixel_config.dart';
import '../../../domain/services/service_shared_preferences.dart';
import '../service_shared_preferences_impl.dart';

typedef SheetsTokenProvider = Future<String> Function();

class _AuthClient extends http.BaseClient {
  _AuthClient(this._inner, this._getToken);
  final http.Client _inner;
  final SheetsTokenProvider _getToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String token = await _getToken();
    request.headers['Authorization'] = 'Bearer $token';
    return _inner.send(request);
  }
}

class GoogleSheetsCanvasDb implements ServiceWsDatabase<Map<String, dynamic>> {
  GoogleSheetsCanvasDb({
    required SheetsTokenProvider tokenProvider,
    required String spreadsheetTitleOrId,
    bool isTitle = true,
    String sheetTitle = 'pixel_canvases',
    Duration pollInterval = const Duration(seconds: 5),
    http.Client? httpClient,
    ServiceSharedPreferences? sharedPrefs,
    String? collectionName,
  }) : _tokenProvider = tokenProvider,
       _spreadsheetTitleOrId = spreadsheetTitleOrId,
       _isTitle = isTitle,
       _kSheetTitle = sheetTitle,
       _pollInterval = pollInterval,
       _prefs = sharedPrefs ?? ServiceSharedPreferencesImpl(),
       _collectionName = collectionName ?? 'canvas',
       _http = httpClient ?? http.Client() {
    _startBackgroundSync();
  }

  // ---- Deps/config
  final SheetsTokenProvider _tokenProvider;
  final String _spreadsheetTitleOrId;
  final bool _isTitle;
  final String _kSheetTitle;
  final Duration _pollInterval;
  final http.Client _http;
  final ServiceSharedPreferences _prefs;
  final String _collectionName;

  // ---- Cache/estado de resolución
  static final Map<String, String> _sessionSpreadsheetIdByTitle =
      <String, String>{};
  Future<String>? _resolvingSpreadsheetFuture;
  String? _spreadsheetIdCache;

  // ---- Store + Blocs
  final Map<String, Map<String, Map<String, dynamic>>> _store =
      <String, Map<String, Map<String, dynamic>>>{};
  final Map<String, BlocGeneral<List<Map<String, dynamic>>>> _collections =
      <String, BlocGeneral<List<Map<String, dynamic>>>>{};

  // ---- Debouncers
  final Map<String, Timer> _emitDebouncers = <String, Timer>{};
  final Map<String, Timer> _pushDebouncers = <String, Timer>{};

  bool _disposed = false;
  Timer? _timer;

  static const List<String> _kHeader = <String>[
    'id',
    'width',
    'height',
    'pixelSize',
    'pixels',
  ];

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('GoogleSheetsCanvasDb disposed');
    }
  }

  // --------------------------- SYNC CORE ---------------------------

  Future<void> _ensureSheetAndHeader(String spreadsheetId) async {
    // asegurar hoja
    try {
      final sheets.Spreadsheet ss = await _sheets().spreadsheets.get(
        spreadsheetId,
      );
      final bool exists = (ss.sheets ?? const <sheets.Sheet>[]).any(
        (sheets.Sheet s) => s.properties?.title == _kSheetTitle,
      );
      if (!exists) {
        await _sheets().spreadsheets.batchUpdate(
          sheets.BatchUpdateSpreadsheetRequest.fromJson(<String, dynamic>{
            'requests': <Map<String, Object?>>[
              <String, Object?>{
                'addSheet': <String, Object?>{
                  'properties': <String, Object?>{'title': _kSheetTitle},
                },
              },
            ],
          }),
          spreadsheetId,
        );
      }
    } catch (_) {
      // si falla el get, intenta crear la hoja
      await _sheets().spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest.fromJson(<String, dynamic>{
          'requests': <Map<String, Object?>>[
            <String, Object?>{
              'addSheet': <String, Object?>{
                'properties': <String, Object?>{'title': _kSheetTitle},
              },
            },
          ],
        }),
        spreadsheetId,
      );
    }

    // asegurar header
    try {
      final sheets.ValueRange resp = await _sheets().spreadsheets.values.get(
        spreadsheetId,
        '$_kSheetTitle!A1:E1',
      );
      final bool ok =
          (resp.values?.isNotEmpty ?? false) &&
          (resp.values!.first.length >= _kHeader.length);
      if (!ok) {
        await _writeHeader(spreadsheetId);
      }
    } catch (_) {
      await _writeHeader(spreadsheetId);
    }
  }

  Future<void> _writeHeader(String spreadsheetId) {
    return _sheets().spreadsheets.values.update(
      sheets.ValueRange(values: <List<Object?>>[_kHeader]),
      spreadsheetId,
      '$_kSheetTitle!A1:E1',
      valueInputOption: 'RAW',
    );
  }

  // ---- APIs
  sheets.SheetsApi _sheets() =>
      sheets.SheetsApi(_AuthClient(_http, _tokenProvider));
  drive.DriveApi _drive() => drive.DriveApi(_AuthClient(_http, _tokenProvider));

  String get _prefsKey => 'pixarra.ssId.$_spreadsheetTitleOrId';

  Future<String> _ensureSpreadsheet() {
    if (_spreadsheetIdCache != null) {
      return Future<String>.value(_spreadsheetIdCache!);
    }

    // Si vino ID directo, úsalo
    if (!_isTitle) {
      _spreadsheetIdCache = _spreadsheetTitleOrId;
      _log(
        'ensureSpreadsheet() cache=$_spreadsheetIdCache isTitle=$_isTitle titleOrId=$_spreadsheetTitleOrId',
      );
      return _ensureSheetAndHeader(
        _spreadsheetIdCache!,
      ).then((_) => _spreadsheetIdCache!);
    }

    // Cache de sesión por título
    final String? sessionId =
        _sessionSpreadsheetIdByTitle[_spreadsheetTitleOrId];
    if (sessionId != null && sessionId.isNotEmpty) {
      _spreadsheetIdCache = sessionId;
      _log(
        'ensureSpreadsheet() cache=$_spreadsheetIdCache isTitle=$_isTitle titleOrId=$_spreadsheetTitleOrId',
      );
      return _ensureSheetAndHeader(sessionId).then((_) => sessionId);
    }

    // Coalescer resolución para evitar carreras
    if (_resolvingSpreadsheetFuture != null) {
      return _resolvingSpreadsheetFuture!;
    }

    _resolvingSpreadsheetFuture = _resolveSpreadsheetDoOnce().whenComplete(() {
      _resolvingSpreadsheetFuture = null;
    });
    return _resolvingSpreadsheetFuture!;
  }

  Future<String> _resolveSpreadsheetDoOnce() async {
    // 1) Intentar prefs
    final String? cached = await _prefs.readString(_prefsKey);
    if (cached != null && cached.isNotEmpty) {
      _spreadsheetIdCache = cached;
      _sessionSpreadsheetIdByTitle[_spreadsheetTitleOrId] = cached;
      _log(
        'ensureSpreadsheet() cache=$_spreadsheetIdCache isTitle=$_isTitle titleOrId=$_spreadsheetTitleOrId',
      );
      await _ensureSheetAndHeader(cached);
      return cached;
    }

    // 2) Listar por título
    final String title = _spreadsheetTitleOrId;
    _log(
      'ensureSpreadsheet() cache=$_spreadsheetIdCache isTitle=$_isTitle titleOrId=$_spreadsheetTitleOrId',
    );
    try {
      final drive.FileList list = await _drive().files.list(
        q: "name='${title.replaceAll("'", r"\'")}' and mimeType='application/vnd.google-apps.spreadsheet' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,name)',
        pageSize: 1,
      );
      if (list.files?.isNotEmpty ?? false) {
        _spreadsheetIdCache = list.files!.first.id;
        _log(
          'ensureSpreadsheet() cache=$_spreadsheetIdCache isTitle=$_isTitle titleOrId=$_spreadsheetTitleOrId',
        );
        await _ensureSheetAndHeader(_spreadsheetIdCache!);
        _sessionSpreadsheetIdByTitle[title] = _spreadsheetIdCache!;
        await _prefs.writeString(_prefsKey, _spreadsheetIdCache!);
        return _spreadsheetIdCache!;
      }
    } catch (e) {
      _log(
        'ensureSpreadsheet() cache=$_spreadsheetIdCache isTitle=$_isTitle titleOrId=$_spreadsheetTitleOrId',
      );
    }

    // 3) Crear UNA vez
    try {
      final drive.File created = await _drive().files.create(
        drive.File()
          ..name = title
          ..mimeType = 'application/vnd.google-apps.spreadsheet',
      );
      _spreadsheetIdCache = created.id;
      _log('[SheetsDb] Created spreadsheet via Drive: id=$_spreadsheetIdCache');
    } catch (e) {
      _log(
        '[SheetsDb][WARN] Drive create failed, fallback to Sheets.create: $e',
      );
      final sheets.Spreadsheet created = await _sheets().spreadsheets.create(
        sheets.Spreadsheet.fromJson(<String, dynamic>{
          'properties': <String, dynamic>{'title': title},
        }),
      );
      _spreadsheetIdCache = created.spreadsheetId;
      _log(
        '[SheetsDb] Created spreadsheet via Sheets: id=$_spreadsheetIdCache',
      );
    }

    await _ensureSheetAndHeader(_spreadsheetIdCache!);
    _sessionSpreadsheetIdByTitle[title] = _spreadsheetIdCache!;
    await _prefs.writeString(_prefsKey, _spreadsheetIdCache!);
    return _spreadsheetIdCache!;
  }

  // ------------------------ In-memory + emit ------------------------

  BlocGeneral<List<Map<String, dynamic>>> _ensureCollectionBloc(
    String collection,
  ) {
    return _collections.putIfAbsent(collection, () {
      final BlocGeneral<List<Map<String, dynamic>>> bloc =
          BlocGeneral<List<Map<String, dynamic>>>(<Map<String, dynamic>>[]);
      final List<Map<String, dynamic>> seed =
          _store[collection]?.values.toList() ?? <Map<String, dynamic>>[];
      if (seed.isNotEmpty) {
        bloc.value = List<Map<String, dynamic>>.unmodifiable(seed);
      }
      return bloc;
    });
  }

  void _emitCollectionDebounced(
    String collection, {
    Duration delay = const Duration(milliseconds: 16),
  }) {
    _emitDebouncers[collection]?.cancel();
    _emitDebouncers[collection] = Timer(delay, () {
      final Map<String, Map<String, dynamic>> docs =
          _store[collection] ?? <String, Map<String, dynamic>>{};
      final BlocGeneral<List<Map<String, dynamic>>> bloc =
          _ensureCollectionBloc(collection);
      bloc.value = List<Map<String, dynamic>>.unmodifiable(docs.values);
    });
  }

  void _schedulePushToSheets(
    String collection,
    String docId,
    Map<String, dynamic> toSave, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    final String key = '$collection/$docId';
    _pushDebouncers[key]?.cancel();
    _pushDebouncers[key] = Timer(delay, () async {
      try {
        final String ssId = await _ensureSpreadsheet();
        await _ensureSheetAndHeader(ssId);
        final int? row = await _findRowById(ssId, docId);
        final List<Object?> rowValues = _toRow(toSave);
        if (row == null) {
          await _sheets().spreadsheets.values.append(
            sheets.ValueRange(values: <List<Object?>>[rowValues]),
            ssId,
            _kSheetTitle,
            valueInputOption: 'RAW',
            insertDataOption: 'INSERT_ROWS',
          );
        } else {
          await _sheets().spreadsheets.values.update(
            sheets.ValueRange(values: <List<Object?>>[rowValues]),
            ssId,
            '$_kSheetTitle!A$row:E$row',
            valueInputOption: 'RAW',
          );
        }
      } catch (e) {
        _log('[SheetsDb][PUSH][WARN] $e');
      }
    });
  }

  // ------------------------ CRUD (Local -> Sheets) -------------------

  @override
  Future<void> saveDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> document,
  }) async {
    _ensureNotDisposed();
    if (collection.isEmpty) {
      throw ArgumentError('collection must not be empty');
    }
    if (docId.isEmpty) {
      throw ArgumentError('docId must not be empty');
    }

    // 1) actualiza memoria y emite (debounced)
    final Map<String, Map<String, dynamic>> docs = _store.putIfAbsent(
      collection,
      () => <String, Map<String, dynamic>>{},
    );
    final Map<String, dynamic> toSave = <String, dynamic>{
      ...document,
      'id': docId,
    };
    docs[docId] = toSave;
    _emitCollectionDebounced(collection);

    if (_hydrated) {
      _schedulePushToSheets(collection, docId, toSave);
    } else {
      _pendingPushes['$collection/$docId'] = toSave;
      _log('defer push until hydrated: $collection/$docId');
    }
  }

  @override
  Future<Map<String, dynamic>> readDocument({
    required String collection,
    required String docId,
  }) async {
    _ensureNotDisposed();
    if (collection.isEmpty) {
      throw ArgumentError('collection must not be empty');
    }
    if (docId.isEmpty) {
      throw ArgumentError('docId must not be empty');
    }

    // 1) intenta memoria
    final Map<String, dynamic>? local = _store[collection]?[docId];
    if (local != null) {
      return local;
    }

    // 2) pull puntual desde sheets
    final String ssId = await _ensureSpreadsheet();
    final int? rowNumber = await _findRowById(ssId, docId);
    if (rowNumber == null) {
      throw StateError('Document not found');
    }

    final sheets.ValueRange resp = await _sheets().spreadsheets.values.get(
      ssId,
      '$_kSheetTitle!A$rowNumber:E$rowNumber',
    );
    final List<List<Object?>> values =
        resp.values?.map((List<Object?> e) => e.cast<Object?>()).toList() ??
        <List<Object?>>[];
    if (values.isEmpty) {
      throw StateError('Row not found');
    }

    final Map<String, dynamic> doc = _fromRow(values.first);
    _store.putIfAbsent(
      collection,
      () => <String, Map<String, dynamic>>{},
    )[docId] = doc;
    _emitCollectionDebounced(collection);

    _pendingPushes.removeWhere((String k, _) => k.endsWith('/$docId'));

    return doc;
  }

  @override
  Future<void> deleteDocument({
    required String collection,
    required String docId,
  }) async {
    _ensureNotDisposed();
    if (collection.isEmpty) {
      throw ArgumentError('collection must not be empty');
    }
    if (docId.isEmpty) {
      throw ArgumentError('docId must not be empty');
    }

    // 1) borra local y emite
    _store[collection]?.remove(docId);
    _emitCollectionDebounced(collection);

    // 2) borra en sheets
    final String ssId = await _ensureSpreadsheet();
    final int? rowNumber = await _findRowById(ssId, docId);
    if (rowNumber == null) {
      return;
    }

    final sheets.Spreadsheet ss = await _sheets().spreadsheets.get(ssId);
    final sheets.Sheet sheet = ss.sheets!.firstWhere(
      (sheets.Sheet s) => s.properties?.title == _kSheetTitle,
      orElse: () => throw StateError('Sheet $_kSheetTitle not found'),
    );
    final int r0 = rowNumber - 1;
    await _sheets().spreadsheets.batchUpdate(
      sheets.BatchUpdateSpreadsheetRequest.fromJson(<String, dynamic>{
        'requests': <Map<String, Object?>>[
          <String, Object?>{
            'deleteDimension': <String, Object?>{
              'range': <String, Object?>{
                'sheetId': sheet.properties!.sheetId,
                'dimension': 'ROWS',
                'startIndex': r0,
                'endIndex': r0 + 1,
              },
            },
          },
        ],
      }),
      ssId,
    );
  }

  // ------------------------ Streams (desde BlocGeneral) ------------------------

  @override
  Stream<Map<String, dynamic>> documentStream({
    required String collection,
    required String docId,
  }) {
    _ensureNotDisposed();
    if (collection.isEmpty) {
      throw ArgumentError('collection must not be empty');
    }
    if (docId.isEmpty) {
      throw ArgumentError('docId must not be empty');
    }

    final BlocGeneral<List<Map<String, dynamic>>> bloc = _ensureCollectionBloc(
      collection,
    );
    final StreamController<Map<String, dynamic>> ctrl =
        StreamController<Map<String, dynamic>>.broadcast();

    // seed si existe
    final Map<String, dynamic>? seed = _store[collection]?[docId];
    if (seed != null) {
      ctrl.add(seed);
    }

    final String key =
        'doc:$collection/$docId#${DateTime.now().microsecondsSinceEpoch}';
    bloc.addFunctionToProcessTValueOnStream(key, (
      List<Map<String, dynamic>> list,
    ) {
      final Map<String, dynamic>? d = list
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (Map<String, dynamic>? e) => e?['id'] == docId,
            orElse: () => null,
          );
      if (d != null) {
        ctrl.add(d);
      }
    }, true);

    ctrl.onCancel = () {
      try {
        bloc.deleteFunctionToProcessTValueOnStream(key);
      } catch (_) {}
      ctrl.close();
    };

    return ctrl.stream;
  }

  @override
  Stream<List<Map<String, dynamic>>> collectionStream({
    required String collection,
  }) {
    _ensureNotDisposed();
    if (collection.isEmpty) {
      throw ArgumentError('collection must not be empty');
    }
    final BlocGeneral<List<Map<String, dynamic>>> bloc = _ensureCollectionBloc(
      collection,
    );
    return bloc.stream;
  }

  // ------------------------ Helpers fila <-> json ------------------------

  List<Object?> _toRow(Map<String, dynamic> json) {
    final String id = Utils.getStringFromDynamic(json['id']);
    final int width = Utils.getIntegerFromDynamic(json['width']);
    final int height = Utils.getIntegerFromDynamic(json['height']);
    final double pixelSize = Utils.getDouble(json['pixelSize']);
    final Map<String, dynamic> pixels = Utils.mapFromDynamic(json['pixels']);
    final String pixelsStr = jsonEncode(pixels);
    return <Object?>[id, width, height, pixelSize, pixelsStr];
  }

  Map<String, dynamic> _fromRow(List<Object?> row) {
    String s(int i) => (i < row.length ? (row[i] ?? '').toString() : '');
    final String id = s(0);
    final int width = int.tryParse(s(1)) ?? 0;
    final int height = int.tryParse(s(2)) ?? 0;
    final double pixelSize = double.tryParse(s(3)) ?? 0.0;
    Map<String, dynamic> pixels = <String, dynamic>{};
    final String p = s(4);
    if (p.isNotEmpty) {
      try {
        pixels = Utils.mapFromDynamic(jsonDecode(p));
      } catch (_) {}
    }
    return <String, dynamic>{
      'id': id,
      'width': width,
      'height': height,
      'pixelSize': pixelSize,
      'pixels': pixels,
    };
  }

  Future<int?> _findRowById(String spreadsheetId, String id) async {
    final sheets.ValueRange resp = await _sheets().spreadsheets.values.get(
      spreadsheetId,
      '$_kSheetTitle!A2:A',
    );
    final List<List<Object?>> values =
        resp.values?.map((List<Object?> e) => e.cast<Object?>()).toList() ??
        <List<Object?>>[];
    for (int i = 0; i < values.length; i++) {
      final String v = (values[i].isNotEmpty
          ? (values[i][0] ?? '').toString()
          : '');
      if (v == id) {
        return 2 + i;
      }
    }
    return null;
  }

  // ------------------------ Background Pull (Sheets -> Local) ------------------
  bool _hydrated = false;
  final Map<String, Map<String, dynamic>> _pendingPushes =
      <String, Map<String, dynamic>>{};

  void _startBackgroundSync() {
    _log('startBackgroundSync()');
    _pullOnceSafely();
    _timer = Timer(_pollInterval, () async {
      if (_disposed) {
        return;
      }
      await _pullOnceSafely();
      _timer = Timer.periodic(_pollInterval, (_) => _pullOnceSafely());
    });
  }

  Future<void> _pullOnceSafely() async {
    try {
      await _pullFromSheets();
    } catch (e) {
      _log('SheetsDb [PULL] error: $e');
    }
  }

  Future<void> _pullFromSheets() async {
    if (_disposed) {
      return;
    }
    final String ssId = await _ensureSpreadsheet();
    _log('PULL from ssId=$ssId sheet=$_kSheetTitle hydrated=$_hydrated');

    final sheets.ValueRange resp = await _sheets().spreadsheets.values.get(
      ssId,
      '$_kSheetTitle!A2:E',
    );

    final List<List<Object?>> rows =
        resp.values?.map((List<Object?> e) => e.cast<Object?>()).toList() ??
        <List<Object?>>[];

    final Map<String, Map<String, dynamic>> docs = _store.putIfAbsent(
      _collectionName,
      () => <String, Map<String, dynamic>>{},
    );

    if (rows.isEmpty) {
      _log(
        'PULL: 0 rows in remote. Mark hydrated and flush any pending pushes.',
      );
      // Importante: marcar hidratado aunque esté vacío
      final bool wasHydrated = _hydrated;
      _hydrated = true;

      // Si había pendientes y antes no estábamos hidratados, súbelos todos (no hay nada remoto que los pise)
      if (!wasHydrated && _pendingPushes.isNotEmpty) {
        final List<MapEntry<String, Map<String, dynamic>>> entries =
            _pendingPushes.entries.toList();
        for (final MapEntry<String, Map<String, dynamic>> e in entries) {
          final String key = e.key; // "collection/docId"
          final Map<String, dynamic> data = e.value;
          final int slash = key.indexOf('/');
          final String col = key.substring(0, slash);
          final String id = key.substring(slash + 1);
          _log('flush deferred push (empty remote): $key');
          _schedulePushToSheets(col, id, data, delay: Duration.zero);
          _pendingPushes.remove(key);
        }
      }
      return;
    }

    int updated = 0;
    for (final List<Object?> r in rows) {
      final Map<String, dynamic> doc = _fromRow(r);
      final String id = Utils.getStringFromDynamic(doc['id']);
      if (id.isEmpty) {
        continue;
      }
      docs[id] = doc;
      updated++;
    }
    _log('PULL: rows=$updated (merged into collection="$_collectionName")');

    if (updated > 0) {
      _emitCollectionDebounced(_collectionName);
    }

    // ---- Marcar hidratado y procesar pendientes ----
    final bool wasHydrated = _hydrated;
    _hydrated = true;

    // ids que EXISTEN en remoto (después de merge)
    final Set<String> remoteIds = docs.keys.toSet();

    if (!wasHydrated && _pendingPushes.isNotEmpty) {
      final List<MapEntry<String, Map<String, dynamic>>> entries =
          _pendingPushes.entries.toList();
      for (final MapEntry<String, Map<String, dynamic>> e in entries) {
        final String key = e.key; // "collection/docId"
        final Map<String, dynamic> data = e.value;
        final int slash = key.indexOf('/');
        final String col = key.substring(0, slash);
        final String id = key.substring(slash + 1);

        if (remoteIds.contains(id)) {
          _log('drop deferred push (remote wins): $key');
          _pendingPushes.remove(key);
          continue;
        }

        _log('flush deferred push (new doc): $key');
        _schedulePushToSheets(col, id, data, delay: Duration.zero);
        _pendingPushes.remove(key);
      }
    }
  }

  // ------------------------ Lifecycle ------------------------

  @override
  void dispose() {
    _timer?.cancel();
    for (final Timer t in _emitDebouncers.values) {
      t.cancel();
    }
    for (final Timer t in _pushDebouncers.values) {
      t.cancel();
    }
    _http.close();
    _disposed = true;
  }

  final bool _verboseLogs = Env.mode != AppMode.prod;
  void _log(String msg) {
    if (_verboseLogs) {
      debugPrint('[SheetsDb] $msg');
    }
  }
}
