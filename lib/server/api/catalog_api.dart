import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../application/catalog/catalog_service.dart';
import 'api_security.dart';
import 'api_support.dart';

class CatalogApi {
  factory CatalogApi({
    required CatalogService catalogService,
    required ApiSecurity security,
    required bool Function() databaseIsHealthy,
  }) => CatalogApi._(catalogService, security, databaseIsHealthy);

  CatalogApi._(this._catalogService, this._security, this._databaseIsHealthy) {
    _router
      ..get('/api/v1/health', _health)
      ..get('/api/v1/worlds', _worlds)
      ..get('/api/v1/worlds/<worldId>/missions', _worldMissions)
      ..get('/api/v1/missions/<missionId>', _mission);
  }

  final CatalogService _catalogService;
  final ApiSecurity _security;
  final bool Function() _databaseIsHealthy;
  final Router _router = Router();

  Handler get handler => _router.call;

  Response _health(Request request) {
    try {
      final healthy = _databaseIsHealthy();
      return jsonResponse(healthy ? 200 : 503, {
        'status': healthy ? 'ok' : 'unavailable',
        'database': healthy,
      });
    } on Object {
      return errorResponse(
        503,
        'database_unavailable',
        'No fue posible acceder a la base de datos.',
      );
    }
  }

  Future<Response> _worlds(Request request) => guardApi(() async {
    await _security.requireUser(request);
    final worlds = await _catalogService.listWorlds();
    return jsonResponse(200, {
      'worlds': worlds.map((world) => world.toJson()).toList(),
    });
  });

  Future<Response> _worldMissions(Request request, String worldId) {
    return guardApi(() async {
      await _security.requireUser(request);
      final missions = await _catalogService.listWorldMissions(worldId);
      return jsonResponse(200, {
        'missions': missions.map((mission) => mission.toJson()).toList(),
      });
    });
  }

  Future<Response> _mission(Request request, String missionId) {
    return guardApi(() async {
      await _security.requireUser(request);
      final mission = await _catalogService.getMission(missionId);
      return jsonResponse(200, {'mission': mission.toJson()});
    });
  }
}
