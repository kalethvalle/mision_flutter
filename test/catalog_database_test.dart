import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/server/database/catalog_database.dart';
import 'package:mision_flutter/server/repositories/sqlite_catalog_repository.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDirectory;
  late String databasePath;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('flutter_quest_db_');
    databasePath = '${tempDirectory.path}/catalog.sqlite3';
  });

  tearDown(() {
    if (tempDirectory.existsSync()) {
      tempDirectory.deleteSync(recursive: true);
    }
  });

  test('crea el esquema y siembra el catálogo sin duplicados', () async {
    var catalog = CatalogDatabase.open(databasePath);
    expect(_count(catalog, 'schema_migrations'), 5);
    expect(_count(catalog, 'worlds'), 2);
    expect(_count(catalog, 'topics'), 9);
    expect(_count(catalog, 'missions'), 9);
    expect(_count(catalog, 'mission_context_paragraphs'), 18);
    expect(_count(catalog, 'mission_instructions'), 27);
    expect(_count(catalog, 'mission_options'), 27);
    expect(_count(catalog, 'users'), 0);
    expect(_count(catalog, 'sessions'), 0);
    expect(_count(catalog, 'training_attempts'), 0);
    expect(_count(catalog, 'mission_progress'), 0);
    expect(_count(catalog, 'questions'), 0);
    expect(_count(catalog, 'question_options'), 0);
    expect(_count(catalog, 'assessment_attempts'), 0);
    expect(_count(catalog, 'assessment_attempt_questions'), 0);
    expect(_count(catalog, 'assessment_attempt_options'), 0);
    expect(_count(catalog, 'assessment_answers'), 0);
    expect(_count(catalog, 'assessment_world_settings'), 2);
    expect(_count(catalog, 'assessment_sessions'), 0);
    expect(_count(catalog, 'assessment_draft_answers'), 0);
    expect(_count(catalog, 'assessment_attempt_events'), 0);
    expect(
      catalog.database.select('''
        SELECT mission_id
        FROM mission_options
        GROUP BY mission_id
        HAVING SUM(is_correct) != 1
      '''),
      isEmpty,
    );
    expect(
      catalog.database.select('PRAGMA foreign_keys').single.values.single,
      1,
    );
    catalog.close();

    catalog = CatalogDatabase.open(databasePath);
    expect(_count(catalog, 'schema_migrations'), 5);
    expect(_count(catalog, 'worlds'), 2);
    expect(_count(catalog, 'topics'), 9);
    expect(_count(catalog, 'missions'), 9);
    expect(_count(catalog, 'mission_options'), 27);
    catalog.close();
  });

  test('consulta contenido ordenado y conserva integridad en SQLite', () async {
    final catalog = CatalogDatabase.open(databasePath);
    addTearDown(catalog.close);
    final repository = SqliteCatalogRepository(catalog.database);

    final worlds = await repository.listWorlds();
    expect(worlds.map((world) => world.id), ['world_1', 'world_2']);
    expect(worlds.expand((world) => world.topics), hasLength(9));

    final dartMissions = await repository.listWorldMissions('world_1');
    final layoutMissions = await repository.listWorldMissions('world_2');
    expect([...dartMissions, ...layoutMissions], hasLength(9));
    for (final mission in [...dartMissions, ...layoutMissions]) {
      expect(mission.learningContextParagraphs, hasLength(2));
      expect(mission.instructions, hasLength(3));
      expect(mission.options, hasLength(3));
      expect(mission.toJson().keys, isNot(contains('correctOptionId')));
    }

    expect(
      () => catalog.database.execute(
        'UPDATE missions SET topic_id = ? WHERE id = ?',
        ['flutter_row', 'w1_m1'],
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('migra base v4 con índices de parciales existentes', () async {
    final catalog = CatalogDatabase.open(databasePath);
    catalog.database.execute('PRAGMA foreign_keys = OFF');
    _downgradeAssessmentSchemaToV4(catalog.database);
    catalog.database.execute('PRAGMA foreign_keys = ON');
    catalog.close();

    final migrated = CatalogDatabase.open(databasePath);
    addTearDown(migrated.close);
    expect(_count(migrated, 'schema_migrations'), 5);
    expect(_count(migrated, 'assessment_world_settings'), 2);
    final columns = migrated.database
        .select('PRAGMA table_info(assessment_attempts)')
        .map((row) => row['name'])
        .toSet();
    expect(columns, containsAll(['session_id', 'deadline_at', 'annulled_at']));
    expect(
      migrated.database.select(
        "SELECT name FROM sqlite_master WHERE type = 'index' AND name = 'idx_assessment_open'",
      ),
      hasLength(1),
    );
  });
}

void _downgradeAssessmentSchemaToV4(Database database) {
  database.execute('DROP TABLE IF EXISTS assessment_attempt_events');
  database.execute('DROP TABLE IF EXISTS assessment_draft_answers');
  database.execute('DROP INDEX IF EXISTS idx_assessment_session_open');
  database.execute('DROP TABLE IF EXISTS assessment_sessions');
  database.execute('DROP TABLE IF EXISTS assessment_world_settings');
  database.execute(
    'ALTER TABLE assessment_answers RENAME TO assessment_answers_v5',
  );
  database.execute(
    'ALTER TABLE assessment_attempt_options RENAME TO assessment_attempt_options_v5',
  );
  database.execute(
    'ALTER TABLE assessment_attempt_questions RENAME TO assessment_attempt_questions_v5',
  );
  database.execute(
    'ALTER TABLE assessment_attempts RENAME TO assessment_attempts_v5',
  );
  database.execute('DROP INDEX IF EXISTS idx_assessment_open');
  database.execute('DROP INDEX IF EXISTS idx_assessment_history');
  database.execute('''
    CREATE TABLE assessment_attempts (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      world_id TEXT NOT NULL REFERENCES worlds(id) ON DELETE RESTRICT,
      status TEXT NOT NULL CHECK (status IN ('open', 'submitted')),
      started_at TEXT NOT NULL,
      submitted_at TEXT,
      score INTEGER CHECK (score BETWEEN 0 AND 100),
      passed INTEGER CHECK (passed IN (0, 1)),
      correct_answers INTEGER,
      total_questions INTEGER NOT NULL CHECK (total_questions > 0)
    )
  ''');
  database.execute('''
    INSERT INTO assessment_attempts(
      id, user_id, world_id, status, started_at, submitted_at, score, passed,
      correct_answers, total_questions
    )
    SELECT id, user_id, world_id,
      CASE WHEN status = 'annulled' THEN 'open' ELSE status END,
      started_at, submitted_at, score, passed, correct_answers, total_questions
    FROM assessment_attempts_v5
  ''');
  database.execute('''
    CREATE UNIQUE INDEX idx_assessment_open
    ON assessment_attempts(user_id, world_id)
    WHERE status = 'open'
  ''');
  database.execute('''
    CREATE INDEX idx_assessment_history
    ON assessment_attempts(user_id, submitted_at)
  ''');
  database.execute('''
    CREATE TABLE assessment_attempt_questions (
      attempt_id TEXT NOT NULL
        REFERENCES assessment_attempts(id) ON DELETE CASCADE,
      question_id TEXT NOT NULL,
      position INTEGER NOT NULL,
      topic_id TEXT NOT NULL,
      topic_title TEXT NOT NULL,
      prompt TEXT NOT NULL,
      question_type TEXT NOT NULL CHECK (question_type IN ('single', 'multiple')),
      explanation TEXT NOT NULL,
      content_version INTEGER NOT NULL,
      PRIMARY KEY(attempt_id, question_id),
      UNIQUE(attempt_id, position)
    )
  ''');
  database.execute('''
    INSERT INTO assessment_attempt_questions
    SELECT * FROM assessment_attempt_questions_v5
  ''');
  database.execute('''
    CREATE TABLE assessment_attempt_options (
      attempt_id TEXT NOT NULL,
      question_id TEXT NOT NULL,
      option_id TEXT NOT NULL,
      text TEXT NOT NULL,
      sort_order INTEGER NOT NULL,
      is_correct INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
      PRIMARY KEY(attempt_id, question_id, option_id),
      UNIQUE(attempt_id, question_id, sort_order),
      FOREIGN KEY(attempt_id, question_id)
        REFERENCES assessment_attempt_questions(attempt_id, question_id)
        ON DELETE CASCADE
    )
  ''');
  database.execute('''
    INSERT INTO assessment_attempt_options
    SELECT * FROM assessment_attempt_options_v5
  ''');
  database.execute('''
    CREATE TABLE assessment_answers (
      attempt_id TEXT NOT NULL,
      question_id TEXT NOT NULL,
      option_id TEXT NOT NULL,
      PRIMARY KEY(attempt_id, question_id, option_id),
      FOREIGN KEY(attempt_id, question_id, option_id)
        REFERENCES assessment_attempt_options(attempt_id, question_id, option_id)
        ON DELETE RESTRICT
    )
  ''');
  database.execute('''
    INSERT INTO assessment_answers
    SELECT * FROM assessment_answers_v5
  ''');
  database.execute('DROP TABLE assessment_answers_v5');
  database.execute('DROP TABLE assessment_attempt_options_v5');
  database.execute('DROP TABLE assessment_attempt_questions_v5');
  database.execute('DROP TABLE assessment_attempts_v5');
  database.execute('DELETE FROM schema_migrations WHERE version = 5');
}

int _count(CatalogDatabase catalog, String table) {
  const allowed = {
    'schema_migrations',
    'worlds',
    'topics',
    'missions',
    'mission_context_paragraphs',
    'mission_instructions',
    'mission_options',
    'users',
    'sessions',
    'training_attempts',
    'mission_progress',
    'questions',
    'question_options',
    'assessment_attempts',
    'assessment_attempt_questions',
    'assessment_attempt_options',
    'assessment_answers',
    'assessment_world_settings',
    'assessment_sessions',
    'assessment_draft_answers',
    'assessment_attempt_events',
  };
  if (!allowed.contains(table)) throw ArgumentError.value(table);
  return catalog.database
          .select('SELECT COUNT(*) AS total FROM $table')
          .single['total']!
      as int;
}
