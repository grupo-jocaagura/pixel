import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

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
  }) : _tokenProvider = tokenProvider,
       _spreadsheetTitleOrId = spreadsheetTitleOrId,
       _isTitle = isTitle,
       _kSheetTitle = sheetTitle,
       _pollInterval = pollInterval,
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
  // --- Cache de sesión (título -> spreadsheetId)
  static final Map<String, String> _sessionSpreadsheetIdByTitle =
      <String, String>{};

  // --- Future en curso para evitar carreras por sesión/título
  Future<String>? _resolvingSpreadsheetFuture;

  // ---- APIs
  sheets.SheetsApi _sheets() =>
      sheets.SheetsApi(_AuthClient(_http, _tokenProvider));
  drive.DriveApi _drive() => drive.DriveApi(_AuthClient(_http, _tokenProvider));

  // ---- Estado interno
  final Map<String, Map<String, Map<String, dynamic>>> _store =
      <
        String,
        Map<String, Map<String, dynamic>>
      >{}; // collection -> docId -> doc
  final Map<String, BlocGeneral<List<Map<String, dynamic>>>> _collections =
      <String, BlocGeneral<List<Map<String, dynamic>>>>{};
  String? _spreadsheetIdCache;
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

  Future<String> _ensureSpreadsheet() {
    if (_spreadsheetIdCache != null) {
      return Future<String>.value(_spreadsheetIdCache!);
    }

    // 0) cache de sesión por título (solo si isTitle)
    if (_isTitle) {
      final String? cached =
          _sessionSpreadsheetIdByTitle[_spreadsheetTitleOrId];
      if (cached != null && cached.isNotEmpty) {
        _spreadsheetIdCache = cached;
        // No hace falta volver a crear header cada vez, pero es seguro:
        return _ensureSheetAndHeader(cached).then((_) => cached);
      }
    }

    // 1) coalescer (si ya alguien lo está resolviendo, reusar esa Future)
    if (_resolvingSpreadsheetFuture != null) {
      return _resolvingSpreadsheetFuture!;
    }

    // 2) resolver (list o create) una sola vez
    _resolvingSpreadsheetFuture = _resolveSpreadsheetDoOnce().whenComplete(() {
      _resolvingSpreadsheetFuture = null;
    });

    return _resolvingSpreadsheetFuture!;
  }

  Future<String> _resolveSpreadsheetDoOnce() async {
    if (!_isTitle) {
      _spreadsheetIdCache = _spreadsheetTitleOrId;
      await _ensureSheetAndHeader(_spreadsheetIdCache!);
      return _spreadsheetIdCache!;
    }

    final String title = _spreadsheetTitleOrId;

    // Primero intenta listar (solo verás archivos de la app con drive.file)
    try {
      final drive.FileList list = await _drive().files.list(
        q:
            "name='${title.replaceAll("'", r"\'")}' and "
            "mimeType='application/vnd.google-apps.spreadsheet' and trashed=false",
        spaces: 'drive',
        $fields: 'files(id,name)',
        pageSize: 1,
      );
      if (list.files?.isNotEmpty ?? false) {
        _spreadsheetIdCache = list.files!.first.id;
        await _ensureSheetAndHeader(_spreadsheetIdCache!);
        _sessionSpreadsheetIdByTitle[title] = _spreadsheetIdCache!;
        return _spreadsheetIdCache!;
      }
    } catch (e) {
      log('Error al crear $e');
    }

    // Si no existe, crea UNA sola vez (como estamos dentro del coalescer no habrá duplicados)
    try {
      final drive.File created = await _drive().files.create(
        drive.File()
          ..name = title
          ..mimeType = 'application/vnd.google-apps.spreadsheet',
      );
      _spreadsheetIdCache = created.id;
    } catch (e) {
      final sheets.Spreadsheet created = await _sheets().spreadsheets.create(
        sheets.Spreadsheet.fromJson(<String, dynamic>{
          'properties': <String, dynamic>{'title': title},
        }),
      );
      _spreadsheetIdCache = created.spreadsheetId;
    }

    await _ensureSheetAndHeader(_spreadsheetIdCache!);
    _sessionSpreadsheetIdByTitle[title] = _spreadsheetIdCache!;
    return _spreadsheetIdCache!;
  }

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
    } catch (e) {
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
    } catch (e) {
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

  // ------------------------ In-memory + emit ------------------------

  BlocGeneral<List<Map<String, dynamic>>> _ensureCollectionBloc(
    String collection,
  ) {
    return _collections.putIfAbsent(collection, () {
      final BlocGeneral<List<Map<String, dynamic>>> bloc =
          BlocGeneral<List<Map<String, dynamic>>>(<Map<String, dynamic>>[]);
      // seed desde store si hubiera
      final List<Map<String, dynamic>> seed =
          _store[collection]?.values.toList() ?? <Map<String, dynamic>>[];
      if (seed.isNotEmpty) {
        bloc.value = List<Map<String, dynamic>>.unmodifiable(seed);
      }
      return bloc;
    });
  }

  void _emitCollection(String collection) {
    final Map<String, Map<String, dynamic>> docs = _store.putIfAbsent(
      collection,
      () => <String, Map<String, dynamic>>{},
    );
    final BlocGeneral<List<Map<String, dynamic>>> bloc = _ensureCollectionBloc(
      collection,
    );
    bloc.value = List<Map<String, dynamic>>.unmodifiable(docs.values);
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

    // 1) actualiza memoria y emite
    final Map<String, Map<String, dynamic>> docs = _store.putIfAbsent(
      collection,
      () => <String, Map<String, dynamic>>{},
    );
    final Map<String, dynamic> toSave = <String, dynamic>{
      ...document,
      'id': docId,
    };
    docs[docId] = toSave;
    _emitCollection(collection);

    // 2) push a sheets (local wins)
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
    _emitCollection(collection);
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
    _emitCollection(collection);

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
    // Stream derivado: filtra y entrega solo el docId pedido
    final StreamController<Map<String, dynamic>> ctrl =
        StreamController<Map<String, dynamic>>.broadcast();

    // seed si existe
    final Map<String, dynamic>? seed = _store[collection]?[docId];
    if (seed != null) {
      ctrl.add(seed);
    }

    // suscripción reactiva (usar funciones nombradas si deseas remover luego)
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
      // quitar listener
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
    // devolvemos el stream del bloc (Bloc<T> de tu dominio expone stream)
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

  void _startBackgroundSync() {
    // Primer tick “lazy” para no bloquear el arranque
    _timer = Timer(_pollInterval, () async {
      if (_disposed) {
        return;
      }
      await _pullOnceSafely();
      // loop
      _timer = Timer.periodic(_pollInterval, (_) => _pullOnceSafely());
    });
  }

  Future<void> _pullOnceSafely() async {
    try {
      await _pullFromSheets();
    } catch (e) {
      log('Error al crear $e');
    }
  }

  /// Lee esta sheet y sincroniza _store (solo sobrescribe si el doc existe en Sheets)
  Future<void> _pullFromSheets() async {
    if (_disposed) {
      return;
    }
    final String ssId = await _ensureSpreadsheet();

    final sheets.ValueRange resp = await _sheets().spreadsheets.values.get(
      ssId,
      '$_kSheetTitle!A2:E',
    );
    final List<List<Object?>> rows =
        resp.values?.map((List<Object?> e) => e.cast<Object?>()).toList() ??
        <List<Object?>>[];

    if (rows.isEmpty) {
      return;
    }

    // Por ahora esto va a una sola "collection" lógica según tu uso (“canvases”)
    const String collection = 'canvases';
    final Map<String, Map<String, dynamic>> docs = _store.putIfAbsent(
      collection,
      () => <String, Map<String, dynamic>>{},
    );

    int updated = 0;
    for (final List<Object?> r in rows) {
      final Map<String, dynamic> doc = _fromRow(r);
      final String id = Utils.getStringFromDynamic(doc['id']);
      if (id.isEmpty) {
        continue;
      }
      // política: gana Sheets solo si doc existe allá (pull)
      docs[id] = doc;
      updated++;
    }
    if (updated > 0) {
      _emitCollection(collection);
    }
  }

  // ------------------------ Lifecycle ------------------------

  @override
  void dispose() {
    _timer?.cancel();
    _http.close();
    _disposed = true;
  }
}
