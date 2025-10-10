import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuthException;
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

class FirebaseAuthErrorMapper implements ErrorMapper {
  const FirebaseAuthErrorMapper({this.provider = 'firebase'});
  final String provider;

  @override
  ErrorItem fromException(
    Object error,
    StackTrace stackTrace, {
    String location = 'unknown',
  }) {
    if (error is FirebaseAuthException) {
      final String code = error.code.trim().toLowerCase();
      final ErrorItem base = _mapFirebaseCode(code);
      return base.copyWith(
        description: (error.message?.isNotEmpty ?? false)
            ? error.message!
            : base.description,
        meta: <String, dynamic>{
          ...base.meta,
          'provider': provider,
          'location': location,
          'rawCode': code,
        },
      );
    }
    return const DefaultErrorMapper().fromException(
      error,
      stackTrace,
      location: location,
    );
  }

  @override
  ErrorItem? fromPayload(
    Map<String, dynamic> payload, {
    String location = 'unknown',
  }) {
    final ErrorItem? e = const DefaultErrorMapper().fromPayload(
      payload,
      location: location,
    );
    return e?.copyWith(
      meta: <String, dynamic>{...e.meta, 'provider': provider},
    );
  }

  static ErrorItem _mapFirebaseCode(String code) {
    switch (code) {
      // email/password
      case 'invalid-email':
        return SessionErrorItems.invalidEmailFormat;
      case 'user-not-found':
        return SessionErrorItems.userNotFound;
      case 'wrong-password':
      case 'invalid-password':
      case 'invalid-login-credentials':
        return SessionErrorItems.invalidCredentials;
      case 'email-already-in-use':
        return SessionErrorItems.emailAlreadyInUse;
      case 'user-disabled':
        return SessionErrorItems.accountDisabled;

      // token / sesión
      case 'id-token-expired':
      case 'user-token-expired':
      case 'token-expired':
        return SessionErrorItems.tokenExpired;
      case 'invalid-id-token':
      case 'invalid-credential':
        return SessionErrorItems.tokenInvalid;
      case 'user-token-revoked':
        return SessionErrorItems.tokenRevoked;

      // federado / proveedor
      case 'account-exists-with-different-credential':
        return SessionErrorItems.accountExistsWithDifferentCredential;
      case 'popup-closed-by-user':
        return SessionErrorItems.providerCancelled;
      case 'operation-not-allowed':
        return SessionErrorItems.serviceUnavailable;

      // red / límites
      case 'network-request-failed':
        return SessionErrorItems.networkUnavailable;
      case 'too-many-requests':
        return SessionErrorItems.rateLimited;
      case 'timeout':
      case 'deadline-exceeded':
        return SessionErrorItems.timeout;
      case 'cancelled':
        return SessionErrorItems.operationCancelled;

      default:
        return SessionErrorItems.fromReason(code);
    }
  }
}
