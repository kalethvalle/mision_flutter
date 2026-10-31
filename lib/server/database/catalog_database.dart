import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import 'catalog_seed.dart';

class CatalogDatabase {
  CatalogDatabase._(this.database, this.databasePath);

  final Database database;
  final String databasePath;

  static CatalogDatabase open(String databasePath) {
    final absolutePath = path.absolute(databasePath);
    Directory(path.dirname(absolutePath)).createSync(recursive: true);
    final database = sqlite3.open(absolutePath);
    final catalog = CatalogDatabase._(database, absolutePath);
    try {
      catalog._initialize();
      return catalog;
    } on Object {
      database.close();
      rethrow;
    }
  }

  void _initialize() {
    database.execute('PRAGMA foreign_keys = ON');
    database.execute('PRAGMA busy_timeout = 5000');
    database.execute('''
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        applied_at TEXT NOT NULL
      )
    ''');

    if (!_migrationApplied(1)) _applyMigrationOne();
    if (!_migrationApplied(2)) _applyMigrationTwo();
    if (!_migrationApplied(3)) _applyMigrationThree();
    _seedCatalog();
  }

  bool _migrationApplied(int version) {
    return database.select(
      'SELECT version FROM schema_migrations WHERE version = ?',
      [version],
    ).isNotEmpty;
  }

  void _applyMigrationOne() {
    _transaction(() {
      database.execute('''
        CREATE TABLE worlds (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          icon_key TEXT NOT NULL,
          color_hex TEXT NOT NULL,
          sort_order INTEGER NOT NULL UNIQUE,
          status TEXT NOT NULL CHECK (status IN ('draft', 'published'))
        )
      ''');
      database.execute('''
        CREATE TABLE topics (
          id TEXT PRIMARY KEY,
          world_id TEXT NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          status TEXT NOT NULL CHECK (status IN ('draft', 'published')),
          UNIQUE(id, world_id),
          UNIQUE(world_id, sort_order)
        )
      ''');
      database.execute('''
        CREATE TABLE missions (
          id TEXT PRIMARY KEY,
          world_id TEXT NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
          topic_id TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          hint TEXT NOT NULL,
          category TEXT NOT NULL,
          code_template TEXT NOT NULL,
          target_placeholder TEXT NOT NULL,
          preview_type TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          status TEXT NOT NULL CHECK (status IN ('draft', 'published')),
          content_version INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY(topic_id, world_id)
            REFERENCES topics(id, world_id) ON DELETE RESTRICT,
          UNIQUE(world_id, sort_order)
        )
      ''');
      database.execute('''
        CREATE TABLE mission_context_paragraphs (
          mission_id TEXT NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
          position INTEGER NOT NULL CHECK (position BETWEEN 1 AND 2),
          text TEXT NOT NULL,
          PRIMARY KEY(mission_id, position)
        )
      ''');
      database.execute('''
        CREATE TABLE mission_instructions (
          mission_id TEXT NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
          position INTEGER NOT NULL CHECK (position BETWEEN 1 AND 3),
          text TEXT NOT NULL,
          PRIMARY KEY(mission_id, position)
        )
      ''');
      database.execute('''
        CREATE TABLE mission_options (
          mission_id TEXT NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
          id TEXT NOT NULL,
          label TEXT NOT NULL,
          code_snippet TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          is_correct INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
          PRIMARY KEY(mission_id, id),
          UNIQUE(mission_id, sort_order)
        )
      ''');
      database.execute(
        'CREATE INDEX idx_topics_world ON topics(world_id, status, sort_order)',
      );
      database.execute(
        'CREATE INDEX idx_missions_world ON missions(world_id, status, sort_order)',
      );
      database.execute(
        '''
        INSERT INTO schema_migrations(version, applied_at)
        VALUES (?, ?)
      ''',
        [1, DateTime.now().toUtc().toIso8601String()],
      );
    });
  }

  void _applyMigrationTwo() {
    _transaction(() {
      database.execute('''
        CREATE TABLE users (
          id TEXT PRIMARY KEY,
          username TEXT NOT NULL,
          username_normalized TEXT NOT NULL UNIQUE,
          display_name TEXT NOT NULL,
          role TEXT NOT NULL CHECK (role IN ('teacher', 'student')),
          password_algorithm TEXT NOT NULL,
          password_salt TEXT NOT NULL,
          password_hash TEXT NOT NULL,
          password_memory INTEGER NOT NULL,
          password_iterations INTEGER NOT NULL,
          password_parallelism INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1))
        )
      ''');
      database.execute('''
        CREATE TABLE sessions (
          token_hash TEXT PRIMARY KEY,
          user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          created_at TEXT NOT NULL,
          last_seen_at TEXT NOT NULL,
          expires_at TEXT NOT NULL
        )
      ''');
      database.execute('''
        CREATE TABLE training_attempts (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          mission_id TEXT NOT NULL REFERENCES missions(id) ON DELETE RESTRICT,
          selected_option_id TEXT NOT NULL,
          is_correct INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
          hint_used INTEGER NOT NULL CHECK (hint_used IN (0, 1)),
          attempted_at TEXT NOT NULL,
          content_version INTEGER NOT NULL,
          FOREIGN KEY(mission_id, selected_option_id)
            REFERENCES mission_options(mission_id, id) ON DELETE RESTRICT
        )
      ''');
      database.execute('''
        CREATE TABLE mission_progress (
          user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          mission_id TEXT NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
          completed_at TEXT NOT NULL,
          last_attempt_at TEXT NOT NULL,
          PRIMARY KEY(user_id, mission_id)
        )
      ''');
      database.execute(
        'CREATE INDEX idx_sessions_user ON sessions(user_id, expires_at)',
      );
      database.execute('''
        CREATE INDEX idx_attempts_user_mission
        ON training_attempts(user_id, mission_id, attempted_at)
      ''');
      database.execute('''
        CREATE INDEX idx_progress_user
        ON mission_progress(user_id, mission_id)
      ''');
      database.execute(
        '''
        INSERT INTO schema_migrations(version, applied_at)
        VALUES (?, ?)
      ''',
        [2, DateTime.now().toUtc().toIso8601String()],
      );
    });
  }

  void _applyMigrationThree() {
    _transaction(() {
      database.execute('''
        ALTER TABLE mission_options
        ADD COLUMN is_active INTEGER NOT NULL DEFAULT 1
          CHECK (is_active IN (0, 1))
      ''');
      database.execute('''
        CREATE TABLE questions (
          id TEXT PRIMARY KEY,
          world_id TEXT NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
          topic_id TEXT NOT NULL,
          prompt TEXT NOT NULL,
          question_type TEXT NOT NULL
            CHECK (question_type IN ('single', 'multiple')),
          explanation TEXT NOT NULL,
          status TEXT NOT NULL CHECK (status IN ('draft', 'published')),
          content_version INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY(topic_id, world_id)
            REFERENCES topics(id, world_id) ON DELETE RESTRICT
        )
      ''');
      database.execute('''
        CREATE TABLE question_options (
          question_id TEXT NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
          id TEXT NOT NULL,
          text TEXT NOT NULL,
          sort_order INTEGER NOT NULL,
          is_correct INTEGER NOT NULL CHECK (is_correct IN (0, 1)),
          PRIMARY KEY(question_id, id),
          UNIQUE(question_id, sort_order)
        )
      ''');
      database.execute('''
        CREATE INDEX idx_questions_scope
        ON questions(world_id, topic_id, status)
      ''');
      database.execute(
        '''
        INSERT INTO schema_migrations(version, applied_at)
        VALUES (?, ?)
      ''',
        [3, DateTime.now().toUtc().toIso8601String()],
      );
    });
  }

  void _seedCatalog() {
    _transaction(() {
      for (final world in seedWorlds) {
        database.execute(
          '''
          INSERT OR IGNORE INTO worlds(
            id, title, description, icon_key, color_hex, sort_order, status
          ) VALUES (?, ?, ?, ?, ?, ?, 'published')
        ''',
          [
            world.id,
            world.title,
            world.description,
            world.iconKey,
            world.colorHex,
            world.sortOrder,
          ],
        );
      }
      for (final topic in seedTopics) {
        database.execute(
          '''
          INSERT OR IGNORE INTO topics(
            id, world_id, title, description, sort_order, status
          ) VALUES (?, ?, ?, ?, ?, 'published')
        ''',
          [
            topic.id,
            topic.worldId,
            topic.title,
            topic.description,
            topic.sortOrder,
          ],
        );
      }
      for (final mission in seedMissions) {
        database.execute(
          '''
          INSERT OR IGNORE INTO missions(
            id, world_id, topic_id, title, description, hint, category,
            code_template, target_placeholder, preview_type, sort_order, status
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'published')
        ''',
          [
            mission.id,
            mission.worldId,
            mission.topicId,
            mission.title,
            mission.description,
            mission.hint,
            mission.category,
            jsonEncode(mission.codeTemplate),
            mission.targetPlaceholder,
            mission.previewType,
            mission.sortOrder,
          ],
        );
        for (var index = 0; index < mission.paragraphs.length; index++) {
          database.execute(
            '''
            INSERT OR IGNORE INTO mission_context_paragraphs(
              mission_id, position, text
            ) VALUES (?, ?, ?)
          ''',
            [mission.id, index + 1, mission.paragraphs[index]],
          );
        }
        for (var index = 0; index < mission.instructions.length; index++) {
          database.execute(
            '''
            INSERT OR IGNORE INTO mission_instructions(
              mission_id, position, text
            ) VALUES (?, ?, ?)
          ''',
            [mission.id, index + 1, mission.instructions[index]],
          );
        }
        for (var index = 0; index < mission.options.length; index++) {
          final option = mission.options[index];
          database.execute(
            '''
            INSERT OR IGNORE INTO mission_options(
              mission_id, id, label, code_snippet, sort_order, is_correct
            ) VALUES (?, ?, ?, ?, ?, ?)
          ''',
            [
              mission.id,
              option.id,
              option.label,
              option.codeSnippet,
              index + 1,
              option.isCorrect ? 1 : 0,
            ],
          );
        }
      }
    });
  }

  void _transaction(void Function() operation) {
    database.execute('BEGIN IMMEDIATE');
    try {
      operation();
      database.execute('COMMIT');
    } on Object {
      database.execute('ROLLBACK');
      rethrow;
    }
  }

  void close() => database.close();
}
