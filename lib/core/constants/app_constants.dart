abstract final class AppConstants {
  static const String appName = 'ObserVita Health Intelligence';
  static const Duration defaultRequestTimeout = Duration(seconds: 30);
  static const int defaultPaginationLimit = 20;

  // Keep environment keys centralized to prevent scattered string literals.
  static const String apiBaseUrlEnv = 'API_BASE_URL';
}