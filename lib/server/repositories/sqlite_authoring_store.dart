import 'dart:convert';

import 'package:sqlite3/sqlite3.dart';

import '../../application/authoring/authoring_service.dart';
import '../../core/models/authoring_model.dart';
import '../../core/models/mission_model.dart';
import '../../core/repositories/catalog_repository.dart';
import '../security/security_service.dart';

class SqliteAuthoringStore implements ContentAuthoringStore {
  SqliteAuthoringStore(
    this._database, {
    SecureTokenService? tokenService,
    DateTime Function()? clock,
  }) : _tokenService = tokenService ?? SecureTokenService(),
       _clock = clock ?? DateTime.now;

  final Database _database;
  final SecureTokenService _tokenService;
  final DateTime Function() _clock;

  @override
  Future<AuthoringCatalog> loadCatalog(List<String> previewTypes) async {
    return AuthoringCatalog(
      worlds: _database
          .select('SELECT * FROM worlds ORDER BY sort_order')
          .map(_worldFromRow)
          .toList(),
      topics: _database
          .select('SELECT * FROM topics ORDER BY world_id, sort_order')
          .map(_topicFromRow)
          .toList(),
      missions: _database
          .select('SELECT * FROM missions ORDER BY world_id, sort_order')
          .map(_missionFromRow)
          .toList(),
      questions: _database
          .select('SELECT * FROM questions ORDER BY world_id, topic_id, rowid')
          .map(_questionFromRow)
          .toList(),
      previewTypes: List.unmodifiable(previewTypes),
    );
  }

  @override
  Future<AuthoringWorld> saveWorld(AuthoringWorld world) async {
    final id = world.id ?? _tokenService.newId();
    _write(() {
      if (world.id == null) {
        _database.execute(
          '''
          INSERT INTO worlds(
            id, title, description, icon_key, color_hex, sort_order, status
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            id,
            world.title.trim(),
            world.description.trim(),
            world.iconKey,
            world.colorHex,
            world.sortOrder,
            world.status.wireName,
          ],
        );
      } else {
        _requireExists('worlds', id, 'world_not_found', 'El mundo no existe.');
        _database.execute(
          '''
          UPDATE worlds SET
            title = ?, description = ?, icon_key = ?, color_hex = ?,
            sort_order = ?, status = ?
          WHERE id = ?
        ''',
          [
            world.title.trim(),
            world.description.trim(),
            world.iconKey,
            world.colorHex,
            world.sortOrder,
            world.status.wireName,
            id,
          ],
        );
      }
    });
    return _worldById(id);
  }

  @override
  Future<AuthoringTopic> saveTopic(AuthoringTopic topic) async {
    final id = topic.id ?? _tokenService.newId();
    _write(() {
      final worldStatus = _worldStatus(topic.worldId);
      if (topic.status == ContentStatus.published &&
          worldStatus != ContentStatus.published) {
        throw const CatalogException(
          'validation_failed',
          'publica el mundo antes de publicar el tema',
        );
      }
      if (topic.id == null) {
        _database.execute(
          '''
          INSERT INTO topics(
            id, world_id, title, description, sort_order, status
          ) VALUES (?, ?, ?, ?, ?, ?)
        ''',
          [
            id,
            topic.worldId,
            topic.title.trim(),
            topic.description.trim(),
            topic.sortOrder,
            topic.status.wireName,
          ],
        );
      } else {
        _requireExists('topics', id, 'topic_not_found', 'El tema no existe.');
        _database.execute(
          '''
          UPDATE topics SET
            world_id = ?, title = ?, description = ?, sort_order = ?, status = ?
          WHERE id = ?
        ''',
          [
            topic.worldId,
            topic.title.trim(),
            topic.description.trim(),
            topic.sortOrder,
            topic.status.wireName,
            id,
          ],
        );
      }
    });
    return _topicById(id);
  }

  @override
  Future<AuthoringMission> saveMission(AuthoringMission mission) async {
    final id = mission.id ?? _tokenService.newId();
    _write(() {
      _requireTopicRelation(
        mission.worldId,
        mission.topicId,
        requirePublished: mission.status == ContentStatus.published,
      );
      if (mission.id == null) {
        _database.execute(
          '''
          INSERT INTO missions(
            id, world_id, topic_id, title, description, hint, category,
            code_template, target_placeholder, preview_type, sort_order,
            status, content_version
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
        ''',
          [
            id,
            mission.worldId,
            mission.topicId,
            mission.title.trim(),
            mission.description.trim(),
            mission.hint.trim(),
            mission.category.wireName,
            jsonEncode(mission.codeTemplate),
            mission.targetPlaceholder,
            mission.previewType,
            mission.sortOrder,
            mission.status.wireName,
          ],
        );
      } else {
        _requireExists(
          'missions',
          id,
          'mission_not_found',
          'La misión no existe.',
        );
        _database.execute(
          '''
          UPDATE missions SET
            world_id = ?, topic_id = ?, title = ?, description = ?, hint = ?,
            category = ?, code_template = ?, target_placeholder = ?,
            preview_type = ?, sort_order = ?, status = ?,
            content_version = content_version + 1
          WHERE id = ?
        ''',
          [
            mission.worldId,
            mission.topicId,
            mission.title.trim(),
            mission.description.trim(),
            mission.hint.trim(),
            mission.category.wireName,
            jsonEncode(mission.codeTemplate),
            mission.targetPlaceholder,
            mission.previewType,
            mission.sortOrder,
            mission.status.wireName,
            id,
          ],
        );
      }
      _replaceMissionChildren(id, mission);
    });
    return _missionById(id);
  }

  @override
  Future<AuthoringQuestion> saveQuestion(AuthoringQuestion question) async {
    final id = question.id ?? _tokenService.newId();
    final now = _clock().toUtc().toIso8601String();
    _write(() {
      _requireTopicRelation(
        question.worldId,
        question.topicId,
        requirePublished: question.status == ContentStatus.published,
      );
      if (question.id == null) {
        _database.execute(
          '''
          INSERT INTO questions(
            id, world_id, topic_id, prompt, question_type, explanation,
            status, content_version, created_at, updated_at
          ) VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?)
        ''',
          [
            id,
            question.worldId,
            question.topicId,
            question.prompt.trim(),
            question.type.wireName,
            question.explanation.trim(),
            question.status.wireName,
            now,
            now,
          ],
        );
      } else {
        _requireExists(
          'questions',
          id,
          'question_not_found',
          'La pregunta no existe.',
        );
        _database.execute(
          '''
          UPDATE questions SET
            world_id = ?, topic_id = ?, prompt = ?, question_type = ?,
            explanation = ?, status = ?, content_version = content_version + 1,
            updated_at = ?
          WHERE id = ?
        ''',
          [
            question.worldId,
            question.topicId,
            question.prompt.trim(),
            question.type.wireName,
            question.explanation.trim(),
            question.status.wireName,
            now,
            id,
          ],
        );
      }
      _database.execute('DELETE FROM question_options WHERE question_id = ?', [
        id,
      ]);
      for (var index = 0; index < question.options.length; index++) {
        final option = question.options[index];
        _database.execute(
          '''
          INSERT INTO question_options(
            question_id, id, text, sort_order, is_correct
          ) VALUES (?, ?, ?, ?, ?)
        ''',
          [
            id,
            option.id,
            option.text.trim(),
            index + 1,
            option.isCorrect ? 1 : 0,
          ],
        );
      }
    });
    return _questionById(id);
  }

  void _replaceMissionChildren(String id, AuthoringMission mission) {
    _database.execute(
      'DELETE FROM mission_context_paragraphs WHERE mission_id = ?',
      [id],
    );
    _database.execute('DELETE FROM mission_instructions WHERE mission_id = ?', [
      id,
    ]);
    for (var index = 0; index < mission.paragraphs.length; index++) {
      _database.execute(
        '''
        INSERT INTO mission_context_paragraphs(mission_id, position, text)
        VALUES (?, ?, ?)
      ''',
        [id, index + 1, mission.paragraphs[index].trim()],
      );
    }
    for (var index = 0; index < mission.instructions.length; index++) {
      _database.execute(
        '''
        INSERT INTO mission_instructions(mission_id, position, text)
        VALUES (?, ?, ?)
      ''',
        [id, index + 1, mission.instructions[index].trim()],
      );
    }
    _database.execute(
      '''
      UPDATE mission_options
      SET is_active = 0, sort_order = -rowid
      WHERE mission_id = ?
    ''',
      [id],
    );
    for (var index = 0; index < mission.options.length; index++) {
      final option = mission.options[index];
      _database.execute(
        '''
        INSERT INTO mission_options(
          mission_id, id, label, code_snippet, sort_order, is_correct, is_active
        ) VALUES (?, ?, ?, ?, ?, ?, 1)
        ON CONFLICT(mission_id, id) DO UPDATE SET
          label = excluded.label,
          code_snippet = excluded.code_snippet,
          sort_order = excluded.sort_order,
          is_correct = excluded.is_correct,
          is_active = 1
      ''',
        [
          id,
          option.id,
          option.label.trim(),
          option.codeSnippet.trim(),
          index + 1,
          option.isCorrect ? 1 : 0,
        ],
      );
    }
  }

  ContentStatus _worldStatus(String worldId) {
    final rows = _database.select('SELECT status FROM worlds WHERE id = ?', [
      worldId,
    ]);
    if (rows.isEmpty) {
      throw const CatalogException('invalid_relation', 'El mundo no existe.');
    }
    return ContentStatus.fromWireName(rows.single['status']! as String);
  }

  void _requireTopicRelation(
    String worldId,
    String topicId, {
    required bool requirePublished,
  }) {
    final rows = _database.select(
      '''
      SELECT w.status AS world_status, t.status AS topic_status
      FROM topics t
      JOIN worlds w ON w.id = t.world_id
      WHERE t.id = ? AND t.world_id = ?
    ''',
      [topicId, worldId],
    );
    if (rows.isEmpty) {
      throw const CatalogException(
        'invalid_relation',
        'El tema no pertenece al mundo seleccionado.',
      );
    }
    if (requirePublished &&
        (rows.single['world_status'] != 'published' ||
            rows.single['topic_status'] != 'published')) {
      throw const CatalogException(
        'validation_failed',
        'publica el mundo y el tema antes de publicar el contenido',
      );
    }
  }

  void _requireExists(String table, String id, String code, String message) {
    const allowed = {'worlds', 'topics', 'missions', 'questions'};
    if (!allowed.contains(table)) throw ArgumentError.value(table);
    if (_database.select('SELECT 1 FROM $table WHERE id = ?', [id]).isEmpty) {
      throw CatalogException(code, message);
    }
  }

  AuthoringWorld _worldById(String id) => _worldFromRow(
    _database.select('SELECT * FROM worlds WHERE id = ?', [id]).single,
  );

  AuthoringTopic _topicById(String id) => _topicFromRow(
    _database.select('SELECT * FROM topics WHERE id = ?', [id]).single,
  );

  AuthoringMission _missionById(String id) => _missionFromRow(
    _database.select('SELECT * FROM missions WHERE id = ?', [id]).single,
  );

  AuthoringQuestion _questionById(String id) => _questionFromRow(
    _database.select('SELECT * FROM questions WHERE id = ?', [id]).single,
  );

  AuthoringWorld _worldFromRow(Row row) => AuthoringWorld(
    id: row['id']! as String,
    title: row['title']! as String,
    description: row['description']! as String,
    iconKey: row['icon_key']! as String,
    colorHex: row['color_hex']! as String,
    sortOrder: row['sort_order']! as int,
    status: ContentStatus.fromWireName(row['status']! as String),
  );

  AuthoringTopic _topicFromRow(Row row) => AuthoringTopic(
    id: row['id']! as String,
    worldId: row['world_id']! as String,
    title: row['title']! as String,
    description: row['description']! as String,
    sortOrder: row['sort_order']! as int,
    status: ContentStatus.fromWireName(row['status']! as String),
  );

  AuthoringMission _missionFromRow(Row row) {
    final id = row['id']! as String;
    return AuthoringMission(
      id: id,
      worldId: row['world_id']! as String,
      topicId: row['topic_id']! as String,
      title: row['title']! as String,
      description: row['description']! as String,
      paragraphs: _orderedText('mission_context_paragraphs', id),
      instructions: _orderedText('mission_instructions', id),
      hint: row['hint']! as String,
      category: MissionCategory.fromWireName(row['category']! as String),
      codeTemplate: (jsonDecode(
        row['code_template']! as String,
      ) as List<Object?>).cast<String>(),
      targetPlaceholder: row['target_placeholder']! as String,
      previewType: row['preview_type']! as String,
      sortOrder: row['sort_order']! as int,
      status: ContentStatus.fromWireName(row['status']! as String),
      contentVersion: row['content_version']! as int,
      options: _database
          .select(
            '''
            SELECT id, label, code_snippet, is_correct
            FROM mission_options
            WHERE mission_id = ? AND is_active = 1
            ORDER BY sort_order
          ''',
            [id],
          )
          .map(
            (option) => AuthoringMissionOption(
              id: option['id']! as String,
              label: option['label']! as String,
              codeSnippet: option['code_snippet']! as String,
              isCorrect: option['is_correct'] == 1,
            ),
          )
          .toList(),
    );
  }

  AuthoringQuestion _questionFromRow(Row row) {
    final id = row['id']! as String;
    return AuthoringQuestion(
      id: id,
      worldId: row['world_id']! as String,
      topicId: row['topic_id']! as String,
      prompt: row['prompt']! as String,
      type: QuestionType.fromWireName(row['question_type']! as String),
      explanation: row['explanation']! as String,
      status: ContentStatus.fromWireName(row['status']! as String),
      contentVersion: row['content_version']! as int,
      options: _database
          .select(
            '''
            SELECT id, text, is_correct
            FROM question_options
            WHERE question_id = ?
            ORDER BY sort_order
          ''',
            [id],
          )
          .map(
            (option) => AuthoringQuestionOption(
              id: option['id']! as String,
              text: option['text']! as String,
              isCorrect: option['is_correct'] == 1,
            ),
          )
          .toList(),
    );
  }

  List<String> _orderedText(String table, String missionId) {
    const allowed = {'mission_context_paragraphs', 'mission_instructions'};
    if (!allowed.contains(table)) throw ArgumentError.value(table);
    return _database
        .select(
          'SELECT text FROM $table WHERE mission_id = ? ORDER BY position',
          [missionId],
        )
        .map((row) => row['text']! as String)
        .toList();
  }

  void _write(void Function() operation) {
    _database.execute('BEGIN IMMEDIATE');
    try {
      operation();
      _database.execute('COMMIT');
    } on CatalogException {
      _database.execute('ROLLBACK');
      rethrow;
    } on SqliteException catch (error) {
      _database.execute('ROLLBACK');
      if (error.resultCode == 19) {
        throw const CatalogException(
          'content_conflict',
          'El identificador o el orden ya está en uso.',
        );
      }
      rethrow;
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }
}
