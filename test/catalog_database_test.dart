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
    expect(_count(catalog, 'schema_migrations'), 4);
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
    expect(_count(catalog, 'schema_migrations'), 4);
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
  };
  if (!allowed.contains(table)) throw ArgumentError.value(table);
  return catalog.database
          .select('SELECT COUNT(*) AS total FROM $table')
          .single['total']!
      as int;
}
