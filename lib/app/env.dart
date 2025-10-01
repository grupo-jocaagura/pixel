import 'pixel_config.dart';

class Env {
  static const String _mode = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'dev',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
  static const String dynamicLinkDomain = String.fromEnvironment(
    'DYNAMIC_LINK_DOMAIN',
    defaultValue: '',
  );
  static const String sheetsTemplateId = String.fromEnvironment(
    'SHEETS_TEMPLATE_ID',
    defaultValue: '',
  );
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
  static const String firebaseEnv = String.fromEnvironment(
    'FIREBASE_ENV',
    defaultValue: 'prod',
  );

  static AppMode get mode {
    switch (_mode) {
      case 'prod':
        return AppMode.prod;
      case 'qa':
        return AppMode.qa;
      case 'dev':
      default:
        return AppMode.dev;
    }
  }
}
