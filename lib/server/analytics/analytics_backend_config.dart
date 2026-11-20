enum AnalyticsBackend { sqlite, mongo }

class AnalyticsBackendConfig {
  const AnalyticsBackendConfig({
    required this.backend,
    this.mongoUri,
    this.mongoDatabase = 'flutter_quest_dw',
    this.refreshMode = 'manual',
  });

  final AnalyticsBackend backend;
  final String? mongoUri;
  final String mongoDatabase;
  final String refreshMode;

  static AnalyticsBackendConfig fromEnvironment(Map<String, String> values) {
    final store = (values['ANALYTICS_STORE'] ?? 'sqlite').trim().toLowerCase();
    final refreshMode = (values['ANALYTICS_REFRESH_MODE'] ?? 'manual')
        .trim()
        .toLowerCase();
    if (refreshMode != 'manual') {
      throw const FormatException(
        'ANALYTICS_REFRESH_MODE solo soporta "manual" en esta version.',
      );
    }

    if (store.isEmpty || store == 'sqlite') {
      return AnalyticsBackendConfig(
        backend: AnalyticsBackend.sqlite,
        refreshMode: refreshMode,
      );
    }

    if (store == 'mongo' || store == 'mongodb') {
      final mongoUri = values['MONGODB_URI']?.trim();
      if (mongoUri == null || mongoUri.isEmpty) {
        throw const FormatException(
          'MONGODB_URI es requerido cuando ANALYTICS_STORE=mongo.',
        );
      }
      final database = values['MONGODB_DATABASE']?.trim();
      return AnalyticsBackendConfig(
        backend: AnalyticsBackend.mongo,
        mongoUri: mongoUri,
        mongoDatabase: database == null || database.isEmpty
            ? 'flutter_quest_dw'
            : database,
        refreshMode: refreshMode,
      );
    }

    throw FormatException(
      'ANALYTICS_STORE debe ser "sqlite" o "mongo", no "$store".',
    );
  }
}
