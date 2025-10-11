import 'pixel_config.dart';

class Env {
  static const String _mode = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'dev',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );
  static const String dynamicLinkDomain = String.fromEnvironment(
    'DYNAMIC_LINK_DOMAIN',
  );
  static const String sheetsTemplateId = String.fromEnvironment(
    'SHEETS_TEMPLATE_ID',
  );
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String firebaseEnv = String.fromEnvironment(
    'FIREBASE_ENV',
    defaultValue: 'dev',
  );

  static bool get isQa => _mode == 'qa';
  static bool get isProd => _mode == 'prod';

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
