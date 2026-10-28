import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../application/catalog/catalog_service.dart';
import '../../core/repositories/catalog_repository.dart';

class CatalogApi {
  factory CatalogApi({
    required CatalogService catalogService,
    required bool Function() databaseIsHealthy,
  }) => CatalogApi._(catalogService, databaseIsHealthy);

  CatalogApi._(this._catalogService, this._databaseIsHealthy) {
    _router
      ..get('/api/v1/health', _health)
      ..get('/api/v1/worlds', _worlds)
      ..get('/api/v1/worlds/<worldId>/missions', _worldMissions)
      ..get('/api/v1/missions/<missionId>', _mission)
      ..post('/api/v1/missions/<missionId>/check', _checkAnswer);
  }

  final CatalogService _catalogService;
  final bool Function() _databaseIsHealthy;
  final Router _router = Router();

  Handler get handler => _router.call;

  Response _health(Request request) {
    try {
      final healthy = _databaseIsHealthy();
      return _json(healthy ? 200 : 503, {
        'status': healthy ? 'ok' : 'unavailable',
        'database': healthy,
      });
    } on Object {
      return _error(
        503,
        'database_unavailable',
        'No fue posible acceder a la base de datos.',
      );
    }
  }

  Future<Response> _worlds(Request request) async {
    return _guard(() async {
      final worlds = await _catalogService.listWorlds();
      return _json(200, {
        'worlds': worlds.map((world) => world.toJson()).toList(),
      });
    });
  }

  Future<Response> _worldMissions(Request request, String worldId) async {
    return _guard(() async {
      final missions = await _catalogService.listWorldMissions(worldId);
      return _json(200, {
        'missions': missions.map((mission) => mission.toJson()).toList(),
      });
    });
  }

  Future<Response> _mission(Request request, String missionId) async {
    return _guard(() async {
      final mission = await _catalogService.getMission(missionId);
      return _json(200, {'mission': mission.toJson()});
    });
  }

  Future<Response> _checkAnswer(Request request, String missionId) async {
    return _guard(() async {
      final body = await _readObject(request);
      final optionId = body['optionId'];
      if (optionId is! String || optionId.trim().isEmpty) {
        throw const CatalogException(
          'invalid_option',
          'El campo "optionId" es obligatorio.',
        );
      }
      final result = await _catalogService.checkMissionAnswer(
        missionId,
        optionId,
      );
      return _json(200, {'result': result.toJson()});
    });
  }

  Future<Map<String, Object?>> _readObject(Request request) async {
    try {
      final value = jsonDecode(await request.readAsString());
      if (value is Map<String, Object?>) return value;
      throw const FormatException();
    } on FormatException {
      throw const CatalogException(
        'invalid_json',
        'El cuerpo debe ser un objeto JSON válido.',
      );
    }
  }

  Future<Response> _guard(Future<Response> Function() operation) async {
    try {
      return await operation();
    } on CatalogException catch (error) {
      final status = switch (error.code) {
        'mission_not_found' => 404,
        'invalid_option' || 'invalid_json' || 'invalid_world_id' => 400,
        _ => 422,
      };
      return _error(status, error.code, error.message);
    } on Object {
      return _error(
        500,
        'internal_error',
        'No fue posible completar la solicitud.',
      );
    }
  }

  Response _json(int status, Map<String, Object?> body) => Response(
    status,
    body: jsonEncode(body),
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );

  Response _error(int status, String code, String message) {
    return _json(status, {
      'error': {'code': code, 'message': message},
    });
  }
}
