import '../../core/models/mission_model.dart';
import '../../core/models/world_model.dart';
import '../../core/repositories/catalog_repository.dart';

class CatalogService {
  const CatalogService(this._repository);

  final CatalogRepository _repository;

  Future<List<WorldModel>> listWorlds() => _repository.listWorlds();

  Future<List<MissionModel>> listWorldMissions(String worldId) {
    if (worldId.trim().isEmpty) {
      throw const CatalogException(
        'invalid_world_id',
        'El identificador del mundo es obligatorio.',
      );
    }
    return _repository.listWorldMissions(worldId);
  }

  Future<MissionModel> getMission(String missionId) async {
    final mission = await _repository.getMission(missionId);
    if (mission == null) {
      throw const CatalogException(
        'mission_not_found',
        'La misión solicitada no existe o no está publicada.',
      );
    }
    return mission;
  }
}
