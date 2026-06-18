class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  // Render dapat membutuhkan cold start cukup lama sebelum Laravel siap.
  static const Duration requestTimeout = Duration(seconds: 60);
}
