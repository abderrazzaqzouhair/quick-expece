/// App-wide configuration resolved at build time via `--dart-define` /
/// `--dart-define-from-file`. Never hardcode environment-specific values
/// (base URLs, publishable keys) in source — read them through this class.
class AppConfig {
  const AppConfig._();

  static const String _envName = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static final Environment environment = Environment.fromName(_envName);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  static bool get isProd => environment == Environment.prod;
}

enum Environment {
  dev,
  staging,
  prod;

  static Environment fromName(String name) => switch (name) {
    'staging' => Environment.staging,
    'prod' => Environment.prod,
    _ => Environment.dev,
  };
}
