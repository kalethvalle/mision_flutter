import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/server/database/catalog_database.dart';

import '../bin/seed_demo_assessments.dart';

void main() {
  late Directory directory;
  late CatalogDatabase database;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('flutter_quest_demo_seed_');
    database = CatalogDatabase.open('${directory.path}/app.sqlite3');
  });

  tearDown(() {
    database.close();
    directory.deleteSync(recursive: true);
  });

  test('carga preguntas demo publicadas de forma idempotente', () {
    expect(seedDemoAssessments(database.database), 9);
    expect(seedDemoAssessments(database.database), 9);

    final questions = database.database.select(
      "SELECT id, world_id, status FROM questions WHERE id LIKE 'demo_%'",
    );
    expect(questions, hasLength(9));
    expect(
      questions.where((row) => row['world_id'] == 'world_1'),
      hasLength(5),
    );
    expect(
      questions.where((row) => row['world_id'] == 'world_2'),
      hasLength(4),
    );
    expect(questions.every((row) => row['status'] == 'published'), isTrue);

    final options = database.database.select('''
      SELECT question_id, COUNT(*) option_count, SUM(is_correct) correct_count
      FROM question_options
      WHERE question_id LIKE 'demo_%'
      GROUP BY question_id
    ''');
    expect(options, hasLength(9));
    expect(options.every((row) => row['option_count'] == 3), isTrue);
    expect(options.every((row) => (row['correct_count'] as int) >= 1), isTrue);
  });
}
