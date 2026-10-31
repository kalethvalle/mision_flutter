import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mision_flutter/core/repositories/catalog_repository.dart';
import 'package:mision_flutter/core/repositories/http_catalog_repository.dart';

import 'support/test_catalog_repository.dart';

void main() {
  test('convierte el contrato HTTP en modelos del catálogo', () async {
    final fixtures = TestCatalogRepository();
    final requests = <String>[];
    final client = MockClient((request) async {
      requests.add('${request.method} ${request.url.path}');
      if (request.url.path == '/api/v1/worlds') {
        return http.Response(
          jsonEncode({
            'worlds': (await fixtures.listWorlds())
                .map((world) => world.toJson())
                .toList(),
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path == '/api/v1/worlds/world_1/missions') {
        return http.Response(
          jsonEncode({
            'missions': fixtures
                .missionsFor('world_1')
                .map((mission) => mission.toJson())
                .toList(),
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      if (request.url.path == '/api/v1/missions/w1_m1/check') {
        final optionId =
            (jsonDecode(request.body) as Map<String, Object?>)['optionId'];
        return http.Response(
          jsonEncode({
            'result': {
              'missionId': 'w1_m1',
              'isCorrect': optionId == 'int',
              'message': optionId == 'int' ? 'Correcta' : 'Incorrecta',
            },
          }),
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response(
        jsonEncode({
          'error': {'code': 'not_found', 'message': 'No encontrado'},
        }),
        404,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final repository = HttpCatalogRepository(
      client: client,
      baseUri: Uri.parse('http://127.0.0.1:8080/api/v1/'),
    );

    expect(await repository.listWorlds(), hasLength(2));
    expect(await repository.listWorldMissions('world_1'), hasLength(5));
    expect(
      (await repository.checkMissionAnswer(
        'w1_m1',
        'int',
        hintUsed: false,
      )).isCorrect,
      isTrue,
    );
    expect(requests, [
      'GET /api/v1/worlds',
      'GET /api/v1/worlds/world_1/missions',
      'POST /api/v1/missions/w1_m1/check',
    ]);
  });

  test('traduce errores HTTP estables', () async {
    final repository = HttpCatalogRepository(
      client: MockClient((_) async {
        return http.Response(
          jsonEncode({
            'error': {
              'code': 'database_unavailable',
              'message': 'Base no disponible',
            },
          }),
          503,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }),
      baseUri: Uri.parse('http://127.0.0.1:8080/api/v1/'),
    );

    expect(
      repository.listWorlds(),
      throwsA(
        isA<CatalogException>()
            .having((error) => error.code, 'code', 'database_unavailable')
            .having((error) => error.message, 'message', 'Base no disponible'),
      ),
    );
  });
}
