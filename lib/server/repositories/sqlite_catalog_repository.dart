import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../core/models/answer_check_result.dart';
import '../../core/models/mission_model.dart';
import '../../core/models/world_model.dart';
import '../../core/repositories/catalog_repository.dart';

class SqliteCatalogRepository implements FlutterQuestRepository {
  const SqliteCatalogRepository(this._database);

  final Database _database;

  bool get isHealthy =>
      _database.select('SELECT 1 AS value').single['value'] == 1;

  @override
  Future<List<WorldModel>> listWorlds() async {
    final rows = _database.select('''
      SELECT id, title, description, icon_key, color_hex
      FROM worlds
      WHERE status = 'published'
      ORDER BY sort_order
    ''');
    return rows.map((row) {
      final worldId = row['id']! as String;
      return WorldModel(
        id: worldId,
        title: row['title']! as String,
        description: row['description']! as String,
        iconKey: row['icon_key']! as String,
        colorHex: row['color_hex']! as String,
        topics: _topicsForWorld(worldId),
      );
    }).toList();
  }

  List<TopicModel> _topicsForWorld(String worldId) {
    return _database
        .select(
          '''
      SELECT id, world_id, title, description
      FROM topics
      WHERE world_id = ? AND status = 'published'
      ORDER BY sort_order
    ''',
          [worldId],
        )
        .map((row) {
          return TopicModel(
            id: row['id']! as String,
            worldId: row['world_id']! as String,
            title: row['title']! as String,
            description: row['description']! as String,
          );
        })
        .toList();
  }

  @override
  Future<List<MissionModel>> listWorldMissions(String worldId) async {
    return _database
        .select(
          '''
      SELECT m.*, w.title AS world_title
      FROM missions m
      JOIN worlds w ON w.id = m.world_id
      JOIN topics t ON t.id = m.topic_id
      WHERE m.world_id = ?
        AND m.status = 'published'
        AND w.status = 'published'
        AND t.status = 'published'
      ORDER BY m.sort_order
    ''',
          [worldId],
        )
        .map(_missionFromRow)
        .toList();
  }

  @override
  Future<MissionModel?> getMission(String missionId) async {
    final rows = _database.select(
      '''
      SELECT m.*, w.title AS world_title
      FROM missions m
      JOIN worlds w ON w.id = m.world_id
      JOIN topics t ON t.id = m.topic_id
      WHERE m.id = ?
        AND m.status = 'published'
        AND w.status = 'published'
        AND t.status = 'published'
    ''',
      [missionId],
    );
    return rows.isEmpty ? null : _missionFromRow(rows.single);
  }

  MissionModel _missionFromRow(Row row) {
    final missionId = row['id']! as String;
    return MissionModel(
      id: missionId,
      worldId: row['world_id']! as String,
      worldTitle: row['world_title']! as String,
      topicId: row['topic_id']! as String,
      missionTitle: row['title']! as String,
      description: row['description']! as String,
      learningContextParagraphs: _orderedText(
        'mission_context_paragraphs',
        missionId,
      ),
      instructions: _orderedText('mission_instructions', missionId),
      hint: row['hint']! as String,
      category: MissionCategory.fromWireName(row['category']! as String),
      codeTemplate: (jsonDecode(
        row['code_template']! as String,
      ) as List<Object?>).cast<String>(),
      targetPlaceholder: row['target_placeholder']! as String,
      options: _optionsForMission(missionId),
      previewType: row['preview_type']! as String,
    );
  }

  List<String> _orderedText(String table, String missionId) {
    if (table != 'mission_context_paragraphs' &&
        table != 'mission_instructions') {
      throw ArgumentError.value(table, 'table');
    }
    return _database
        .select(
          'SELECT text FROM $table WHERE mission_id = ? ORDER BY position',
          [missionId],
        )
        .map((row) => row['text']! as String)
        .toList();
  }

  List<MissionOption> _optionsForMission(String missionId) {
    return _database
        .select(
          '''
      SELECT id, label, code_snippet
      FROM mission_options
      WHERE mission_id = ?
      ORDER BY sort_order
    ''',
          [missionId],
        )
        .map((row) {
          return MissionOption(
            id: row['id']! as String,
            label: row['label']! as String,
            codeSnippet: row['code_snippet']! as String,
          );
        })
        .toList();
  }

  @override
  Future<AnswerCheckResult> checkMissionAnswer(
    String missionId,
    String optionId,
  ) async {
    final mission = _database.select(
      '''
      SELECT id FROM missions WHERE id = ? AND status = 'published'
    ''',
      [missionId],
    );
    if (mission.isEmpty) {
      throw const CatalogException(
        'mission_not_found',
        'La misión solicitada no existe o no está publicada.',
      );
    }

    final option = _database.select(
      '''
      SELECT is_correct
      FROM mission_options
      WHERE mission_id = ? AND id = ?
    ''',
      [missionId, optionId],
    );
    if (option.isEmpty) {
      throw const CatalogException(
        'invalid_option',
        'La opción no pertenece a la misión indicada.',
      );
    }
    final correct = option.single['is_correct'] == 1;
    return AnswerCheckResult(
      missionId: missionId,
      isCorrect: correct,
      message: correct
          ? '¡Excelente! Misión completada.'
          : 'La respuesta no es correcta. Intenta con otra opción.',
    );
  }
}
