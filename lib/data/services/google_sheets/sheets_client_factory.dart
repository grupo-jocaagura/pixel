import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:http/http.dart' as http;

/// HTTP client muy simple que inyecta el Authorization: Bearer <token>
class _AuthClient extends http.BaseClient {
  _AuthClient(this._inner, this._accessToken);
  final http.Client _inner;
  final String _accessToken;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }
}

/// Construye SheetsApi a partir de un accessToken OAuth válido para Sheets scope.
/// - `accessToken`: token con scope `.../auth/spreadsheets`
class SheetsClientFactory {
  static sheets.SheetsApi fromAccessToken(String accessToken) {
    final http.Client base = http.Client();
    final http.Client auth = _AuthClient(base, accessToken);
    return sheets.SheetsApi(auth);
  }
}
