import '../models/answer_check_result.dart';
import '../models/mission_model.dart';
import '../models/world_model.dart';

abstract interface class CatalogRepository {
  Future<List<WorldModel>> listWorlds();

  Future<List<MissionModel>> listWorldMissions(String worldId);

  Future<MissionModel?> getMission(String missionId);
}

abstract interface class MissionAnswerRepository {
  Future<AnswerCheckResult> checkMissionAnswer(
    String missionId,
    String optionId,
  );
}

abstract interface class FlutterQuestRepository
    implements CatalogRepository, MissionAnswerRepository {}

class CatalogException implements Exception {
  const CatalogException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'CatalogException($code): $message';
}
