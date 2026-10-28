import 'package:mision_flutter/core/models/answer_check_result.dart';
import 'package:mision_flutter/core/models/mission_model.dart';
import 'package:mision_flutter/core/models/world_model.dart';
import 'package:mision_flutter/core/repositories/catalog_repository.dart';
import 'package:mision_flutter/server/database/catalog_seed.dart';

class TestCatalogRepository implements FlutterQuestRepository {
  TestCatalogRepository({this.failureMessage});

  final String? failureMessage;

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
    String optionId,
  ) async {
    _failWhenConfigured();
    final correct = correctOptionIds[missionId];
    if (correct == null) {
      throw const CatalogException('mission_not_found', 'Misión inexistente.');
    }
    final mission = seedMissions.singleWhere((item) => item.id == missionId);
    if (!mission.options.any((item) => item.id == optionId)) {
      throw const CatalogException('invalid_option', 'Opción inválida.');
    }
    return AnswerCheckResult(
      missionId: missionId,
      isCorrect: optionId == correct,
      message: optionId == correct ? 'Correcta' : 'Incorrecta',
    );
  }
}
