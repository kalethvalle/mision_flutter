import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/application/authoring/authoring_service.dart';
import 'package:mision_flutter/application/identity/identity_service.dart';
import 'package:mision_flutter/application/progress/progress_service.dart';
import 'package:mision_flutter/core/models/authoring_model.dart';
import 'package:mision_flutter/core/models/user_model.dart';
import 'package:mision_flutter/core/repositories/catalog_repository.dart';
import 'package:mision_flutter/server/database/catalog_database.dart';
import 'package:mision_flutter/server/repositories/sqlite_authoring_store.dart';
import 'package:mision_flutter/server/repositories/sqlite_catalog_repository.dart';
import 'package:mision_flutter/server/repositories/sqlite_identity_store.dart';
import 'package:mision_flutter/server/repositories/sqlite_progress_store.dart';
import 'package:mision_flutter/server/security/security_service.dart';

void main() {
  late Directory directory;
  late String path;
  late CatalogDatabase database;
  late AuthoringService authoring;

  const teacher = UserModel(
    id: 'teacher',
    username: 'teacher',
    displayName: 'Docente',
    role: UserRole.teacher,
  );
  const student = UserModel(
    id: 'student',
    username: 'student',
    displayName: 'Estudiante',
    role: UserRole.student,
  );

  setUp(() {
    directory = Directory.systemTemp.createTempSync('flutter_quest_authoring_');
    path = '${directory.path}/app.sqlite3';
    database = CatalogDatabase.open(path);
    authoring = AuthoringService(SqliteAuthoringStore(database.database));
  });

  tearDown(() {
    database.close();
    directory.deleteSync(recursive: true);
  });

  test('solo docente accede y el borrador persiste tras reiniciar', () async {
    expect(() => authoring.load(student), throwsA(_code('forbidden')));
    final initial = await authoring.load(teacher);
    expect(initial.worlds, hasLength(2));
    expect(initial.missions, hasLength(9));
    expect(initial.questions, isEmpty);

    final draft = await authoring.saveQuestion(
      teacher,
      const AuthoringQuestion(
        worldId: 'world_1',
        topicId: 'dart_numeric_types',
        prompt: '',
        type: QuestionType.single,
        explanation: '',
        status: ContentStatus.draft,
        contentVersion: 1,
        options: [],
      ),
    );
    expect(draft.id, isNotNull);
    expect(draft.status, ContentStatus.draft);

    database.close();
    database = CatalogDatabase.open(path);
    authoring = AuthoringService(SqliteAuthoringStore(database.database));
    final restored = await authoring.load(teacher);
    expect(restored.questions.single.id, draft.id);
    expect(restored.questions.single.status, ContentStatus.draft);
  });

  test('publicación enumera faltas y valida relación mundo-tema', () async {
    expect(
      () => authoring.saveQuestion(
        teacher,
        const AuthoringQuestion(
          worldId: 'world_1',
          topicId: 'dart_numeric_types',
          prompt: '',
          type: QuestionType.single,
          explanation: '',
          status: ContentStatus.published,
          contentVersion: 1,
          options: [],
        ),
      ),
      throwsA(
        isA<CatalogException>()
            .having((error) => error.code, 'code', 'validation_failed')
            .having(
              (error) => error.message,
              'message',
              allOf(
                contains('enunciado'),
                contains('explicación'),
                contains('dos opciones'),
              ),
            ),
      ),
    );
    expect(
      () => authoring.saveQuestion(teacher, _question(topicId: 'flutter_row')),
      throwsA(_code('invalid_relation')),
    );
  });

  test('publica preguntas single y multiple con reglas de solución', () async {
    final single = await authoring.saveQuestion(teacher, _question());
    expect(single.status, ContentStatus.published);
    expect(single.contentVersion, 1);

    expect(
      () => authoring.saveQuestion(
        teacher,
        _question(type: QuestionType.single, correctIds: const {'a', 'b'}),
      ),
      throwsA(_code('validation_failed')),
    );
    final multiple = await authoring.saveQuestion(
      teacher,
      _question(type: QuestionType.multiple, correctIds: const {'a', 'b'}),
    );
    expect(multiple.options.where((option) => option.isCorrect), hasLength(2));
    expect(
      database.database.select(
        "SELECT * FROM questions WHERE status = 'published'",
      ),
      hasLength(2),
    );
  });

  test('borrador de misión queda oculto y aparece al publicarlo', () async {
    final base = (await authoring.load(teacher)).missions.first;
    expect(
      () => authoring.saveMission(
        teacher,
        AuthoringMission(
          worldId: base.worldId,
          topicId: base.topicId,
          title: '',
          description: '',
          paragraphs: const [],
          instructions: const [],
          hint: '',
          category: base.category,
          codeTemplate: const [],
          targetPlaceholder: '',
          previewType: '',
          sortOrder: 6,
          status: ContentStatus.published,
          contentVersion: 1,
          options: const [],
        ),
      ),
      throwsA(
        isA<CatalogException>()
            .having((error) => error.code, 'code', 'validation_failed')
            .having(
              (error) => error.message,
              'message',
              allOf(
                contains('dos párrafos'),
                contains('tres pasos'),
                contains('vista previa'),
              ),
            ),
      ),
    );

    final draft = await authoring.saveMission(
      teacher,
      AuthoringMission(
        worldId: base.worldId,
        topicId: base.topicId,
        title: '',
        description: '',
        paragraphs: const [],
        instructions: const [],
        hint: '',
        category: base.category,
        codeTemplate: const [],
        targetPlaceholder: '',
        previewType: '',
        sortOrder: 6,
        status: ContentStatus.draft,
        contentVersion: 1,
        options: const [],
      ),
    );
    final studentCatalog = SqliteCatalogRepository(database.database);
    expect(await studentCatalog.listWorldMissions('world_1'), hasLength(5));

    final published = await authoring.saveMission(
      teacher,
      AuthoringMission(
        id: draft.id,
        worldId: base.worldId,
        topicId: base.topicId,
        title: 'Misión publicada desde autoría',
        description: base.description,
        paragraphs: base.paragraphs,
        instructions: base.instructions,
        hint: base.hint,
        category: base.category,
        codeTemplate: base.codeTemplate,
        targetPlaceholder: base.targetPlaceholder,
        previewType: base.previewType,
        sortOrder: 6,
        status: ContentStatus.published,
        contentVersion: draft.contentVersion,
        options: base.options,
      ),
    );
    expect(published.contentVersion, 2);
    expect(await studentCatalog.listWorldMissions('world_1'), hasLength(6));
  });

  test('edita misión, incrementa versión y conserva intentos', () async {
    final identity = IdentityService(
      SqliteIdentityStore(
        database.database,
        passwordHasher: PasswordHasher(memory: 64, iterations: 1),
      ),
    );
    final teacherSession = await identity.bootstrapTeacher(
      username: 'teacher',
      displayName: 'Docente',
      password: 'teacher1234',
    );
    final account = await identity.createStudent(
      actor: teacherSession.user,
      username: 'student',
      displayName: 'Estudiante',
      password: 'student1234',
    );
    final progressStore = SqliteProgressStore(database.database);
    final progress = ProgressService(progressStore, progressStore);
    await progress.checkAnswer(
      user: account,
      missionId: 'w1_m1',
      optionId: 'int',
      hintUsed: false,
    );

    final original = (await authoring.load(teacher)).missions
        .firstWhere((mission) => mission.id == 'w1_m1');
    final updated = await authoring.saveMission(
      teacher,
      AuthoringMission(
        id: original.id,
        worldId: original.worldId,
        topicId: original.topicId,
        title: 'Variables actualizadas',
        description: original.description,
        paragraphs: original.paragraphs,
        instructions: original.instructions,
        hint: original.hint,
        category: original.category,
        codeTemplate: original.codeTemplate,
        targetPlaceholder: original.targetPlaceholder,
        previewType: original.previewType,
        sortOrder: original.sortOrder,
        status: original.status,
        contentVersion: original.contentVersion,
        options: original.options,
      ),
    );

    expect(updated.contentVersion, 2);
    final attempts = database.database.select(
      'SELECT * FROM training_attempts',
    );
    expect(attempts, hasLength(1));
    expect(attempts.single['content_version'], 1);
    expect(
      (await SqliteCatalogRepository(database.database).getMission('w1_m1'))!
          .missionTitle,
      'Variables actualizadas',
    );
  });
}

Matcher _code(String code) =>
    isA<CatalogException>().having((error) => error.code, 'code', code);

AuthoringQuestion _question({
  String topicId = 'dart_numeric_types',
  QuestionType type = QuestionType.single,
  Set<String> correctIds = const {'a'},
}) {
  return AuthoringQuestion(
    worldId: 'world_1',
    topicId: topicId,
    prompt: '¿Qué tipo representa un entero?',
    type: type,
    explanation: 'int representa números enteros en Dart.',
    status: ContentStatus.published,
    contentVersion: 1,
    options: [
      AuthoringQuestionOption(
        id: 'a',
        text: 'int',
        isCorrect: correctIds.contains('a'),
      ),
      AuthoringQuestionOption(
        id: 'b',
        text: 'String',
        isCorrect: correctIds.contains('b'),
      ),
    ],
  );
}
