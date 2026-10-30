import '../models/answer_check_result.dart';
import '../models/mission_model.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';
import '../models/world_model.dart';

abstract interface class CatalogRepository {
  Future<List<WorldModel>> listWorlds();

  Future<List<MissionModel>> listWorldMissions(String worldId);

  Future<MissionModel?> getMission(String missionId);
}

abstract interface class MissionAnswerRepository {
  Future<AnswerCheckResult> checkMissionAnswer(
    String missionId,
    String optionId, {
    required bool hintUsed,
  });
}

abstract interface class IdentityRepository {
  Future<AuthSnapshot> getAuthStatus();

  Future<UserModel> bootstrapTeacher({
    required String username,
    required String displayName,
    required String password,
  });

  Future<UserModel> login({required String username, required String password});

  Future<void> logout();

  Future<List<UserModel>> listUsers();

  Future<UserModel> createStudent({
    required String username,
    required String displayName,
    required String password,
  });
}

abstract interface class ProgressRepository {
  Future<StudentProgress> getProgress();
}

abstract interface class FlutterQuestRepository
    implements
        CatalogRepository,
        MissionAnswerRepository,
        IdentityRepository,
        ProgressRepository {}

class CatalogException implements Exception {
  const CatalogException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'CatalogException($code): $message';
}
