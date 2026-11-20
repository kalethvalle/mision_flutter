import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/server/analytics/analytics_backend_config.dart';

void main() {
  test('usa SQLite por defecto para conservar el flujo actual', () {
    final config = AnalyticsBackendConfig.fromEnvironment(const {});

    expect(config.backend, AnalyticsBackend.sqlite);
    expect(config.mongoUri, isNull);
    expect(config.mongoDatabase, 'flutter_quest_dw');
    expect(config.refreshMode, 'manual');
  });

  test('configura MongoDB cuando el store analitico lo solicita', () {
    final config = AnalyticsBackendConfig.fromEnvironment(const {
      'ANALYTICS_STORE': 'mongo',
      'MONGODB_URI':
          'mongodb://quest_app:cambia-esto@mongo:27017/flutter_quest_dw',
      'MONGODB_DATABASE': 'flutter_quest_dw',
    });

    expect(config.backend, AnalyticsBackend.mongo);
    expect(
      config.mongoUri,
      'mongodb://quest_app:cambia-esto@mongo:27017/flutter_quest_dw',
    );
    expect(config.mongoDatabase, 'flutter_quest_dw');
  });

  test('rechaza MongoDB sin URI explicita', () {
    expect(
      () => AnalyticsBackendConfig.fromEnvironment(const {
        'ANALYTICS_STORE': 'mongo',
      }),
      throwsFormatException,
    );
  });

  test('rechaza backends desconocidos', () {
    expect(
      () => AnalyticsBackendConfig.fromEnvironment(const {
        'ANALYTICS_STORE': 'postgres',
      }),
      throwsFormatException,
    );
  });
}
