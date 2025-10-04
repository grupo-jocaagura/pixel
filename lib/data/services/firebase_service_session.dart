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
    String?
    googleClientId, // pásalo en Web/Windows via --dart-define=GOOGLE_CLIENT_ID
    int authStateDebounceMs = 120,
    DateTime Function()? now,
  }) : _auth = auth ?? fb.FirebaseAuth.instance {
    // --- inicializaciones de final en el cuerpo (late final) ---
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

  Future<void> _initGoogle({String? clientId}) async {
    if (_googleInitialized) {
      return;
    }
    final bool isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final bool needsClientId = kIsWeb || isWindows;

    await googlesi.GoogleSignIn.instance.initialize(
      clientId: needsClientId ? clientId : null,
      // serverClientId / hostedDomain si aplica
    );
    _googleInitialized = true;
  }

  void _wireAuthStream() {
    _fbAuthSub = _auth.authStateChanges().listen((fb.User? u) {
      if (_disposed) {
        return;
      }
      // Debounce con la versión de jocaagura: void Function() → envolvemos async inmediatamente.
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
    // API nueva del plugin: authenticate() retorna cuenta con tokens iniciales.
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
    final String token = Utils.getStringFromDynamic(await c.user!.getIdToken());
    final Map<String, dynamic> user = _userToJson(c.user!, token);
    _authCtrl.add(user);
    return user;
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
}
