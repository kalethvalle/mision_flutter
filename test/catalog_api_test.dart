import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/application/catalog/catalog_service.dart';
import 'package:mision_flutter/server/api/catalog_api.dart';
import 'package:mision_flutter/server/database/catalog_database.dart';
import 'package:mision_flutter/server/repositories/sqlite_catalog_repository.dart';
import 'package:shelf/shelf.dart';

void main() {
  late Directory tempDirectory;
  late CatalogDatabase database;
  late CatalogApi api;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('flutter_quest_api_');
    database = CatalogDatabase.open('${tempDirectory.path}/catalog.sqlite3');
    final repository = SqliteCatalogRepository(database.database);
    api = CatalogApi(
      catalogService: CatalogService(repository),
      databaseIsHealthy: () => repository.isHealthy,
    );
  });

  tearDown(() {
    database.close();
    tempDirectory.deleteSync(recursive: true);
  });

  test('expone salud y catálogo sin filtrar soluciones', () async {
    final health = await api.handler(
      Request('GET', Uri.parse('http://localhost/api/v1/health')),
    );
    expect(health.statusCode, 200);

    final response = await api.handler(
      Request('GET', Uri.parse('http://localhost/api/v1/worlds')),
    );
    expect(response.statusCode, 200);
    final body = await response.readAsString();
    expect((jsonDecode(body) as Map<String, Object?>)['worlds'], hasLength(2));
    expect(body, isNot(contains('correctOptionId')));
    expect(body, isNot(contains('isCorrect')));

    final missions = await api.handler(
      Request(
        'GET',
        Uri.parse('http://localhost/api/v1/worlds/world_1/missions'),
      ),
    );
    final missionsBody = await missions.readAsString();
    expect(missions.statusCode, 200);
    expect(
      (jsonDecode(missionsBody) as Map<String, Object?>)['missions'],
      hasLength(5),
    );
    expect(missionsBody, isNot(contains('correctOptionId')));
    expect(missionsBody, isNot(contains('isCorrect')));
  });

  test('comprueba una respuesta y rechaza entradas inválidas', () async {
    final correct = await api.handler(
      _post('/api/v1/missions/w1_m1/check', {'optionId': 'int'}),
    );
    expect(correct.statusCode, 200);
    final result =
        (jsonDecode(await correct.readAsString())
                as Map<String, Object?>)['result']!
            as Map<String, Object?>;
    expect(result['isCorrect'], isTrue);

    final foreignOption = await api.handler(
      _post('/api/v1/missions/w1_m1/check', {'optionId': 'top_right'}),
    );
    expect(foreignOption.statusCode, 400);

    final invalidJson = await api.handler(
      Request(
        'POST',
        Uri.parse('http://localhost/api/v1/missions/w1_m1/check'),
        body: '{',
      ),
    );
    expect(invalidJson.statusCode, 400);

    final missingMission = await api.handler(
      _post('/api/v1/missions/missing/check', {'optionId': 'int'}),
    );
    expect(missingMission.statusCode, 404);
  });
}

Request _post(String path, Map<String, Object?> body) {
  return Request(
    'POST',
    Uri.parse('http://localhost$path'),
    headers: const {'content-type': 'application/json'},
    body: jsonEncode(body),
  );
}
