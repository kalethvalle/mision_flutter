import 'package:mision_flutter/core/models/answer_check_result.dart';
import 'package:mision_flutter/core/models/mission_model.dart';
import 'package:mision_flutter/core/models/progress_model.dart';
import 'package:mision_flutter/core/models/user_model.dart';
import 'package:mision_flutter/core/models/world_model.dart';
import 'package:mision_flutter/core/repositories/catalog_repository.dart';
import 'package:mision_flutter/server/database/catalog_seed.dart';

class TestCatalogRepository implements FlutterQuestRepository {
  TestCatalogRepository({
    this.failureMessage,
    this.bootstrapRequired = false,
    UserModel? authenticatedUser,
  }) : _authenticatedUser = authenticatedUser ?? testStudent,
       _users = [
         if (!bootstrapRequired) testTeacher,
         if (!bootstrapRequired &&
             (authenticatedUser ?? testStudent).id != testTeacher.id)
           authenticatedUser ?? testStudent,
       ];

  final String? failureMessage;
  bool bootstrapRequired;
  UserModel? _authenticatedUser;
  final List<UserModel> _users;
  final Set<String> completedMissionIds = {};
  bool? lastHintUsed;

  Map<String, String> get correctOptionIds => {
    for (final mission in seedMissions)
      mission.id: mission.options.singleWhere((option) => option.isCorrect).id,
  };

  List<MissionModel> missionsFor(String worldId) {
    final worldTitle = seedWorlds
        .singleWhere((world) => world.id == worldId)
        .title;
    return seedMissions.where((mission) => mission.worldId == worldId).map((
      mission,
    ) {
      return MissionModel(
        id: mission.id,
        worldId: mission.worldId,
        worldTitle: worldTitle,
        topicId: mission.topicId,
        missionTitle: mission.title,
        description: mission.description,
        learningContextParagraphs: mission.paragraphs,
        instructions: mission.instructions,
        hint: mission.hint,
        category: MissionCategory.fromWireName(mission.category),
        codeTemplate: mission.codeTemplate,
        targetPlaceholder: mission.targetPlaceholder,
        options: mission.options
            .map(
              (option) => MissionOption(
                id: option.id,
                label: option.label,
                codeSnippet: option.codeSnippet,
              ),
            )
            .toList(),
        previewType: mission.previewType,
      );
    }).toList();
  }

  void _failWhenConfigured() {
    if (failureMessage != null) {
      throw CatalogException('test_failure', failureMessage!);
    }
  }

  @override
  Future<List<WorldModel>> listWorlds() async {
    _failWhenConfigured();
    return seedWorlds.map((world) {
      final topics = seedTopics
          .where((topic) => topic.worldId == world.id)
          .map(
            (topic) => TopicModel(
              id: topic.id,
              worldId: topic.worldId,
              title: topic.title,
              description: topic.description,
            ),
          )
          .toList();
      return WorldModel(
        id: world.id,
        title: world.title,
        description: world.description,
        iconKey: world.iconKey,
        colorHex: world.colorHex,
        topics: topics,
      );
    }).toList();
  }

  @override
  Future<List<MissionModel>> listWorldMissions(String worldId) async {
    _failWhenConfigured();
    return missionsFor(worldId);
  }

  @override
  Future<MissionModel?> getMission(String missionId) async {
    _failWhenConfigured();
    for (final world in seedWorlds) {
      final matches = missionsFor(world.id)
          .where((item) => item.id == missionId);
      if (matches.isNotEmpty) return matches.first;
    }
    return null;
  }

  @override
  Future<AnswerCheckResult> checkMissionAnswer(
    String missionId,
    String optionId, {
    required bool hintUsed,
  }) async {
    _failWhenConfigured();
    final correct = correctOptionIds[missionId];
    if (correct == null) {
      throw const CatalogException('mission_not_found', 'Misión inexistente.');
    }
    final mission = seedMissions.singleWhere((item) => item.id == missionId);
    if (!mission.options.any((item) => item.id == optionId)) {
      throw const CatalogException('invalid_option', 'Opción inválida.');
    }
    lastHintUsed = hintUsed;
    if (optionId == correct) completedMissionIds.add(missionId);
    return AnswerCheckResult(
      missionId: missionId,
      isCorrect: optionId == correct,
      message: optionId == correct ? 'Correcta' : 'Incorrecta',
      progress: await getProgress(),
    );
  }

  @override
  Future<AuthSnapshot> getAuthStatus() async {
    return AuthSnapshot(
      bootstrapRequired: bootstrapRequired,
      user: bootstrapRequired ? null : _authenticatedUser,
    );
  }

  @override
  Future<UserModel> bootstrapTeacher({
    required String username,
    required String displayName,
    required String password,
  }) async {
    if (!bootstrapRequired) {
      throw const CatalogException('bootstrap_completed', 'Ya existe docente.');
    }
    final user = UserModel(
      id: 'teacher_created',
      username: username,
      displayName: displayName,
      role: UserRole.teacher,
    );
    bootstrapRequired = false;
    _authenticatedUser = user;
    _users.add(user);
    return user;
  }

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final matches = _users.where((user) => user.username == username);
    if (matches.isEmpty || password != 'student1234') {
      throw const CatalogException(
        'invalid_credentials',
        'Usuario o clave incorrectos.',
      );
    }
    _authenticatedUser = matches.first;
    return matches.first;
  }

  @override
  Future<void> logout() async {
    _authenticatedUser = null;
  }

  @override
  Future<List<UserModel>> listUsers() async => List.unmodifiable(_users);

  @override
  Future<UserModel> createStudent({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final user = UserModel(
      id: 'student_${_users.length}',
      username: username,
      displayName: displayName,
      role: UserRole.student,
    );
    _users.add(user);
    return user;
  }

  @override
  Future<StudentProgress> getProgress() async {
    _failWhenConfigured();
    final worlds = <WorldProgressState>[];
    final missions = <MissionProgressState>[];
    var previousWorldComplete = true;
    for (var worldIndex = 0; worldIndex < seedWorlds.length; worldIndex++) {
      final world = seedWorlds[worldIndex];
      final worldMissions = seedMissions
          .where((mission) => mission.worldId == world.id)
          .toList();
      final worldUnlocked = worldIndex == 0 || previousWorldComplete;
      var previousMissionComplete = true;
      var completedCount = 0;
      for (var index = 0; index < worldMissions.length; index++) {
        final mission = worldMissions[index];
        final completed = completedMissionIds.contains(mission.id);
        if (completed) completedCount++;
        missions.add(
          MissionProgressState(
            missionId: mission.id,
            worldId: world.id,
            isCompleted: completed,
            isUnlocked:
                completed ||
                (worldUnlocked && (index == 0 || previousMissionComplete)),
          ),
        );
        previousMissionComplete = completed;
      }
      worlds.add(
        WorldProgressState(
          worldId: world.id,
          completedMissions: completedCount,
          totalMissions: worldMissions.length,
          isUnlocked: worldUnlocked,
          lockReason: worldUnlocked ? null : 'Completa el mundo anterior.',
        ),
      );
      previousWorldComplete = completedCount == worldMissions.length;
    }
    return StudentProgress(worlds: worlds, missions: missions);
  }
}

const testTeacher = UserModel(
  id: 'teacher_1',
  username: 'teacher',
  displayName: 'Docente',
  role: UserRole.teacher,
);

const testStudent = UserModel(
  id: 'student_1',
  username: 'student',
  displayName: 'Estudiante',
  role: UserRole.student,
);
