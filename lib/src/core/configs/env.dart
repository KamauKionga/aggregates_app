/// Simple environment helpers. Use --dart-define=ENV=dev|staging|prod in CI.
class Env {
  static const String env = String.fromEnvironment('ENV', defaultValue: 'prod');

  static bool get isDev => env == 'dev';
  static bool get isStaging => env == 'staging';
  static bool get isProd => env == 'prod';
}
