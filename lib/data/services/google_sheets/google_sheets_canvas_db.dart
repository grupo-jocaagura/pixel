import 'dart:convert';

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
    http.Client? httpClient,
  }) : _tokenProvider = tokenProvider,
       _spreadsheetTitleOrId = spreadsheetTitleOrId,
       _isTitle = isTitle,
       _http = httpClient ?? http.Client();

  final SheetsTokenProvider _tokenProvider;
  final String _spreadsheetTitleOrId;
  final bool _isTitle;
  final http.Client _http;

  String? _spreadsheetIdCache;
  bool _disposed = false;

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('GoogleSheetsCanvasDb disposed');
    }
  }

  /// Crea un SheetsApi **con token fresco** para cada operación.
  sheets.SheetsApi _sheets() {
    return sheets.SheetsApi(_AuthClient(_http, _tokenProvider));
  }

  static const String _kSheetTitle = 'pixel_canvases';
  static const List<String> _kHeader = <String>[
    'id',
    'width',
    'height',
    'pixelSize',
    'pixels',
  ];

  Future<String> _ensureSpreadsheet() async {
    if (_spreadsheetIdCache != null) {
      return _spreadsheetIdCache!;
    }
    if (!_isTitle) {
      _spreadsheetIdCache = _spreadsheetTitleOrId;
      await _ensureSheetAndHeader(_spreadsheetIdCache!);
      return _spreadsheetIdCache!;
    }
    final sheets.Spreadsheet created = await _sheets().spreadsheets.create(
      sheets.Spreadsheet.fromJson(<String, dynamic>{
        'properties': <String, dynamic>{'title': _spreadsheetTitleOrId},
        'sheets': <dynamic>[
          <String, Map<String, String>>{
            'properties': <String, String>{'title': _kSheetTitle},
          },
        ],
      }),
    );
    _spreadsheetIdCache = created.spreadsheetId;
    await _ensureHeader(_spreadsheetIdCache!);
    return _spreadsheetIdCache!;
  }

  Future<void> _ensureSheetAndHeader(String spreadsheetId) async {
    try {
      final sheets.ValueRange resp = await _sheets().spreadsheets.values.get(
        spreadsheetId,
        '$_kSheetTitle!A1:E1',
      );
      final bool ok =
          (resp.values?.isNotEmpty ?? false) &&
          (resp.values!.first.length >= _kHeader.length);
      if (!ok) {
        await _ensureHeader(spreadsheetId);
      }
    } catch (_) {
      await _sheets().spreadsheets.batchUpdate(
        sheets.BatchUpdateSpreadsheetRequest.fromJson(<dynamic, dynamic>{
          'requests': <Map<String, Map<String, Map<String, String>>>>[
            <String, Map<String, Map<String, String>>>{
              'addSheet': <String, Map<String, String>>{
                'properties': <String, String>{'title': _kSheetTitle},
              },
            },
          ],
        }),
        spreadsheetId,
      );
      await _ensureHeader(spreadsheetId);
    }
  }

  Future<void> _ensureHeader(String spreadsheetId) {
    return _sheets().spreadsheets.values.update(
      sheets.ValueRange(values: <List<Object?>>[_kHeader]),
      spreadsheetId,
      '$_kSheetTitle!A1:E1',
      valueInputOption: 'RAW',
    );
  }

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

  // ----------------- ServiceWsDatabase impl -----------------

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

    final String ssId = await _ensureSpreadsheet();
    await _ensureSheetAndHeader(ssId);

    final List<Object?> row = _toRow(<String, dynamic>{
      ...document,
      'id': docId,
    });
    final int? rowNumber = await _findRowById(ssId, docId);
    final sheets.SheetsApi api = _sheets();

    if (rowNumber == null) {
      await api.spreadsheets.values.append(
        sheets.ValueRange(values: <List<Object?>>[row]),
        ssId,
        _kSheetTitle,
        valueInputOption: 'RAW',
        insertDataOption: 'INSERT_ROWS',
      );
    } else {
      await api.spreadsheets.values.update(
        sheets.ValueRange(values: <List<Object?>>[row]),
        ssId,
        '$_kSheetTitle!A$rowNumber:E$rowNumber',
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
    return _fromRow(values.first);
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
      sheets.BatchUpdateSpreadsheetRequest.fromJson(<dynamic, dynamic>{
        'requests': <Map<String, Map<String, Map<String, Object?>>>>[
          <String, Map<String, Map<String, Object?>>>{
            'deleteDimension': <String, Map<String, Object?>>{
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

  @override
  Stream<Map<String, dynamic>> documentStream({
    required String collection,
    required String docId,
  }) => throw UnsupportedError('documentStream not supported for Sheets');

  @override
  Stream<List<Map<String, dynamic>>> collectionStream({
    required String collection,
  }) => throw UnsupportedError('collectionStream not supported for Sheets');

  @override
  void dispose() {
    _http.close();
    _disposed = true;
  }
}
