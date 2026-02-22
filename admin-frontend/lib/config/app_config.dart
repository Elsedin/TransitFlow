class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5178/api',
  );
  
  static const String appName = 'TransitFlow Administrator';
}
