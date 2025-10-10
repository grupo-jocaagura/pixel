import 'google_sheets_canvas_db.dart';

/// Evita popups simultáneos: si ya hay un token en curso, reusa esa Future.
class CoalescedTokenProvider {
  CoalescedTokenProvider(this._inner);
  final SheetsTokenProvider _inner;

  Future<String>? _inFlight;

  Future<String> call() {
    if (_inFlight != null) {
      return _inFlight!;
    }
    final Future<String> fut = _inner().whenComplete(() => _inFlight = null);
    _inFlight = fut;
    return fut;
  }
}
