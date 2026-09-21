class AppConstants {
  static const String appName = 'VyparaAI';
  /// Defaults to local development for desktop/web. Android emulators should
  /// pass `--dart-define=API_BASE_URL=http://10.0.2.2:8000`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://vyaparai-rtx0.onrender.com',
  );

  /// Network logs can include sensitive headers and must be explicitly enabled.
  static const bool enableLogging = bool.fromEnvironment(
    'ENABLE_LOGGING',
    defaultValue: false,
  );
}
