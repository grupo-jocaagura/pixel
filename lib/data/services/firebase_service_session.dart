import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart' as googlesi;
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart'
    show Debouncer, ServiceSession, Utils;

/// Implementación real de ServiceSession usando FirebaseAuth + Google Sign-In.
/// - Trabaja EXCLUSIVAMENTE con Map (como FakeServiceSession).
/// - authStateChanges() emite Map? con el MISMO shape del fake:
///   { id, displayName, photoUrl, email, jwt{accessToken, issuedAt, expiresAt} }
class FirebaseServiceSession implements ServiceSession {
  FirebaseServiceSession({
    fb.FirebaseAuth? auth,
    String? googleClientId,
    int authStateDebounceMs = 120,
    DateTime Function()? now,
  }) : _auth = auth ?? fb.FirebaseAuth.instance {
    _now = now ?? () => DateTime.now().toUtc();
    _debouncer = Debouncer(milliseconds: authStateDebounceMs);

    _initGoogle(clientId: googleClientId);
    _wireAuthStream();
  }

  final fb.FirebaseAuth _auth;

  // Se inicializan en el constructor (late final para evitar final_not_initialized_constructor)
  late final DateTime Function() _now;
  late final Debouncer _debouncer;

  StreamSubscription<fb.User?>? _fbAuthSub;
  final StreamController<Map<String, dynamic>?> _authCtrl =
      StreamController<Map<String, dynamic>?>.broadcast();
  bool _disposed = false;
  bool _googleInitialized = false;

  Completer<void>? _gsiInitCompleter;
  bool _webRedirectHandled = false;

  /// Llama esto una sola vez tras inicializar Firebase en Web.
  /// Captura el accessToken del flujo "signInWithRedirect" y lo cachea.
  Future<void> processRedirectResultOnce() async {
    if (!kIsWeb || _webRedirectHandled) return;
    _webRedirectHandled = true;
    try {
      final fb.UserCredential c = await _auth.getRedirectResult();
      final fb.User? u = c.user;
      if (u != null) {
        // cachea el accessToken OAuth (Google) si viene
        final String? at = c.credential?.accessToken;
        if (at != null && at.isNotEmpty) {
          _cacheToken(at);
        }
        // emite usuario normal (Firebase ID token)
        final String idToken = Utils.getStringFromDynamic(await u.getIdToken());
        _authCtrl.add(_userToJson(u, idToken));
      }
    } catch (e) {
      // opcional: loggear
    }
  }

  Future<void> _initGoogle({String? clientId}) async {
    if (_googleInitialized) return;
    _gsiInitCompleter ??= Completer<void>();
    try {
      if (!kIsWeb) {
        await googlesi.GoogleSignIn.instance.initialize(
          clientId: (clientId != null && clientId.isNotEmpty) ? clientId : null,
        );
      }
    } catch (_) {}
    _googleInitialized = true;
    if (!_gsiInitCompleter!.isCompleted) {
      _gsiInitCompleter!.complete();
    }
  }

  void _wireAuthStream() {
    _fbAuthSub = _auth.authStateChanges().listen((fb.User? u) {
      if (_disposed) {
        return;
      }

      _debouncer(() {
        (() async {
          if (u == null) {
            _authCtrl.add(null);
          } else {
            final String token = Utils.getStringFromDynamic(
              await u.getIdToken(),
            );
            _authCtrl.add(_userToJson(u, token));
          }
        })();
      });
    });
  }

  Map<String, dynamic> _userToJson(
    fb.User u,
    String idToken, {
    DateTime? issuedAt,
    Duration ttl = const Duration(hours: 1),
  }) {
    final DateTime iat = issuedAt ?? _now();
    return <String, dynamic>{
      'id': u.uid,
      'displayName': u.displayName ?? (u.email?.split('@').first ?? 'user'),
      'photoUrl': u.photoURL,
      'email': u.email ?? '',
      'jwt': <String, dynamic>{
        'accessToken': idToken,
        'issuedAt': iat.toIso8601String(),
        'expiresAt': iat.add(ttl).toIso8601String(),
      },
    };
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('FirebaseServiceSession has been disposed');
    }
  }

  // ---------------- ServiceSession API (shape idéntico al fake) ----------------

  @override
  Future<Map<String, dynamic>> signInUserAndPassword({
    required String email,
    required String password,
  }) async {
    _checkDisposed();
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password must not be empty');
    }
    final fb.UserCredential c = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final String token = Utils.getStringFromDynamic(await c.user!.getIdToken());
    final Map<String, dynamic> user = _userToJson(c.user!, token);
    _authCtrl.add(user);
    return user;
  }

  @override
  Future<Map<String, dynamic>> logInUserAndPassword({
    required String email,
    required String password,
  }) async {
    _checkDisposed();
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email and password must not be empty');
    }
    final fb.UserCredential c = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final String token = Utils.getStringFromDynamic(await c.user!.getIdToken());
    final Map<String, dynamic> user = _userToJson(c.user!, token);
    _authCtrl.add(user);
    return user;
  }

  @override
  Future<Map<String, dynamic>> logInWithGoogle() async {
    _checkDisposed();

    final bool isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final bool isMacOS =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final bool isLinux =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

    try {
      // ---------- WEB ----------
      if (kIsWeb) {
        final fb.GoogleAuthProvider provider = fb.GoogleAuthProvider()
          ..addScope(_kSheetsScope)
          ..addScope(_kDriveFileScope)
          ..setCustomParameters(<String, String>{'prompt': 'select_account'});

        try {
          final fb.UserCredential c = await _auth.signInWithPopup(provider);
          final fb.User? u = c.user;

          // ⬇️ cachea el accessToken de OAuth para Sheets/Drive
          final String? at = c.credential?.accessToken;
          if (at != null && at.isNotEmpty) {
            _cacheToken(at);
          }

          final String idToken = Utils.getStringFromDynamic(
            await u!.getIdToken(),
          );
          final Map<String, dynamic> user = _userToJson(u, idToken);
          _authCtrl.add(user);
          return user;
        } on fb.FirebaseAuthException catch (e) {
          if (e.code == 'popup-blocked' || e.code == 'popup-closed-by-user') {
            await _auth.signInWithRedirect(provider);
            return <String, dynamic>{'pendingRedirect': true};
          }
          rethrow;
        }
      }

      // ---------- DESKTOP (Windows/macOS/Linux) ----------
      if (isWindows || isMacOS || isLinux) {
        final fb.GoogleAuthProvider provider = fb.GoogleAuthProvider()
          ..setCustomParameters(<String, String>{'prompt': 'select_account'});

        final fb.UserCredential c = await _auth.signInWithProvider(provider);
        final fb.User? u = c.user;

        final String token = Utils.getStringFromDynamic(await u!.getIdToken());

        final Map<String, dynamic> user = _userToJson(u, token);
        _authCtrl.add(user);
        return user;
      }

      // ---------- ANDROID / iOS ----------
      final googlesi.GoogleSignInAccount account = await googlesi
          .GoogleSignIn
          .instance
          .authenticate();

      final googlesi.GoogleSignInAuthentication authz = account.authentication;
      final String? idToken = authz.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In did not return an idToken');
      }

      final fb.OAuthCredential cred = fb.GoogleAuthProvider.credential(
        idToken: idToken,
      );
      final fb.UserCredential c = await _auth.signInWithCredential(cred);
      final fb.User? u = c.user;

      final String token = Utils.getStringFromDynamic(await u!.getIdToken());

      final Map<String, dynamic> user = _userToJson(u, token);
      _authCtrl.add(user);
      return user;
    } catch (e) {
      rethrow;
    } finally {}
  }

  @override
  Future<Map<String, dynamic>> logInSilently(
    Map<String, dynamic> sessionJson,
  ) async {
    _checkDisposed();
    final fb.User? u = _auth.currentUser;
    if (u == null) {
      throw StateError('No active session');
    }
    final String token = Utils.getStringFromDynamic(await u.getIdToken());
    final Map<String, dynamic> user = _userToJson(u, token);
    _authCtrl.add(user);
    return user;
  }

  @override
  Future<Map<String, dynamic>> refreshSession(
    Map<String, dynamic> sessionJson,
  ) async {
    _checkDisposed();
    final fb.User? u = _auth.currentUser;
    if (u == null) {
      throw StateError('No active session');
    }
    final String token = Utils.getStringFromDynamic(
      await u.getIdToken(true),
    ); // fuerza refresh
    final Map<String, dynamic> user = _userToJson(u, token, issuedAt: _now());

    // Mantén compatibilidad con el fake: refrescar jwt y propagar al stream
    final Map<String, dynamic> next = Map<String, dynamic>.from(sessionJson);
    final Map<String, dynamic> jwt = Map<String, dynamic>.from(
      Utils.mapFromDynamic(next['jwt']),
    );
    final Map<String, dynamic> userMap = Utils.mapFromDynamic(user['jwt']);

    jwt['accessToken'] = Utils.getStringFromDynamic(userMap['accessToken']);
    jwt['refreshedAt'] = Utils.getStringFromDynamic(userMap['issuedAt']);
    jwt['expiresAt'] = Utils.getStringFromDynamic(userMap['expiresAt']);
    next['jwt'] = jwt;

    _authCtrl.add(next);
    return next;
  }

  @override
  Future<Map<String, dynamic>> recoverPassword({required String email}) async {
    _checkDisposed();
    if (email.isEmpty) {
      throw ArgumentError('Email must not be empty');
    }
    await _auth.sendPasswordResetEmail(email: email);
    return <String, dynamic>{
      'ok': true,
      'message': 'Recovery email sent',
      'email': email,
    };
  }

  @override
  Future<Map<String, dynamic>> logOutUser(
    Map<String, dynamic> sessionJson,
  ) async {
    _checkDisposed();
    await _auth.signOut();
    try {
      await googlesi.GoogleSignIn.instance.disconnect();
    } catch (_) {}
    _authCtrl.add(null);
    return <String, dynamic>{'ok': true, 'message': 'Logged out'};
  }

  @override
  Future<Map<String, dynamic>> getCurrentUser() async {
    _checkDisposed();
    final fb.User? u = _auth.currentUser;
    if (u == null) {
      throw StateError('No active session');
    }
    final String token = Utils.getStringFromDynamic(await u.getIdToken());
    return _userToJson(u, token);
  }

  @override
  Future<Map<String, dynamic>> isSignedIn() async {
    _checkDisposed();
    return <String, dynamic>{'isSignedIn': _auth.currentUser != null};
  }

  @override
  Stream<Map<String, dynamic>?> authStateChanges() {
    _checkDisposed();
    return _authCtrl.stream;
  }

  @override
  void dispose() {
    if (!_disposed) {
      _fbAuthSub?.cancel();
      _authCtrl.close();
      _disposed = true;
    }
  }

  static const String _kSheetsScope =
      'https://www.googleapis.com/auth/spreadsheets';
  // (Opcional) Para patrón de “sólo archivos de la app” a nivel de flujo (no cambia el texto del consent)
  static const String _kDriveFileScope =
      'https://www.googleapis.com/auth/drive.file';

  // Cache mínimamente conservadora (los tokens suelen durar ~1h; usamos margen)
  String? _cachedSheetsAccessToken;
  DateTime? _cachedSheetsIssuedAt;
  final Duration _tokenTtl = const Duration(minutes: 50);

  // En FirebaseServiceSession
  Future<String>? _sheetsTokenInFlight;
  bool _popupOpen = false;

  Future<String> sheetsAccessToken() async {
    _checkDisposed();
    await _ensureGoogleInit();

    // Reusar la misma Future si ya hay una en curso
    if (_sheetsTokenInFlight != null) {
      return _sheetsTokenInFlight!;
    }

    // Cache fresco
    if (_cachedSheetsAccessToken != null && _cachedSheetsIssuedAt != null) {
      if (DateTime.now().isBefore(_cachedSheetsIssuedAt!.add(_tokenTtl))) {
        return _cachedSheetsAccessToken!;
      }
    }

    // Creamos la Future y la compartimos con todos los que llamen mientras esté en curso
    final Completer<String> completer = Completer<String>();
    _sheetsTokenInFlight = completer.future;

    try {
      final String token = await _getSheetsTokenInternal();
      _cacheToken(token);
      completer.complete(token);
      return token;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      // al terminar, liberamos
      _sheetsTokenInFlight = null;
      _popupOpen = false;
    }
  }

  Future<String> _getSheetsTokenInternal() async {
    final bool isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final bool isLinux =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;
    if (isWindows || isLinux) {
      throw UnsupportedError(
        'Sheets OAuth token no disponible en Windows/Linux con google_sign_in v6.',
      );
    }

    if (kIsWeb) {
      final String? at = _cachedSheetsAccessToken;
      if (at != null &&
          _cachedSheetsIssuedAt != null &&
          DateTime.now().isBefore(_cachedSheetsIssuedAt!.add(_tokenTtl))) {
        return at;
      }
      throw StateError(
        'No cached Sheets access token on Web; require user gesture to refresh.',
      );
    }

    // Android/iOS/macOS con google_sign_in v6
    final googlesi.GoogleSignIn gs = googlesi.GoogleSignIn.instance;

    // Silencioso primero
    final Map<String, String>? silentHeaders = await gs.authorizationClient
        .authorizationHeaders(<String>[_kSheetsScope, _kDriveFileScope]);
    if (silentHeaders != null) {
      final String? bearer = silentHeaders['Authorization'];
      if (bearer != null && bearer.startsWith('Bearer ')) {
        return bearer.substring(7);
      }
    }

    if (gs.supportsAuthenticate()) {
      if (_popupOpen) {
        throw StateError('Otro flujo de auth ya está abierto.');
      }
      _popupOpen = true;

      final googlesi.GoogleSignInAccount account = await gs.authenticate(
        scopeHint: <String>[_kSheetsScope, _kDriveFileScope],
      );

      final Map<String, String>? headers = await account.authorizationClient
          .authorizationHeaders(<String>[
            _kSheetsScope,
            _kDriveFileScope,
          ], promptIfNecessary: true);
      if (headers == null) {
        throw StateError('No headers para Sheets.');
      }
      final String? bearer = headers['Authorization'];
      if (bearer == null || !bearer.startsWith('Bearer ')) {
        throw StateError('Authorization header inválido.');
      }
      return bearer.substring(7);
    }

    throw UnsupportedError('authenticate() no soportado y no hay fallback.');
  }

  void _cacheToken(String token) {
    _cachedSheetsAccessToken = token;
    _cachedSheetsIssuedAt = DateTime.now();
  }

  /// Si recibes 401/invalid token desde Sheets, llama a esto y reintenta una vez.
  Future<void> clearSheetsAccessToken({String? lastAccessToken}) async {
    _cachedSheetsAccessToken = null;
    _cachedSheetsIssuedAt = null;
    // Cuando tengas el access token usado, puedes intentar invalidarlo:
    // await googlesi.GoogleSignIn.instance.authorizationClient
    //   .clearAuthorizationToken(accessToken: lastAccessToken ?? '');
  }

  Future<void> _ensureGoogleInit() async {
    if (_googleInitialized) {
      return;
    }
    // por si se llama antes de que initialize termine
    await (_gsiInitCompleter?.future ?? Future<void>.value());
  }
}
