import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/application/assessment/assessment_service.dart';
import 'package:mision_flutter/application/authoring/authoring_service.dart';
import 'package:mision_flutter/application/identity/identity_service.dart';
import 'package:mision_flutter/application/progress/progress_service.dart';
import 'package:mision_flutter/core/models/assessment_model.dart';
import 'package:mision_flutter/core/models/authoring_model.dart';
import 'package:mision_flutter/core/models/user_model.dart';
import 'package:mision_flutter/core/repositories/catalog_repository.dart';
import 'package:mision_flutter/server/database/catalog_database.dart';
import 'package:mision_flutter/server/database/catalog_seed.dart';
import 'package:mision_flutter/server/repositories/sqlite_assessment_store.dart';
import 'package:mision_flutter/server/repositories/sqlite_authoring_store.dart';
import 'package:mision_flutter/server/repositories/sqlite_identity_store.dart';
import 'package:mision_flutter/server/repositories/sqlite_progress_store.dart';
import 'package:mision_flutter/server/security/security_service.dart';

void main() {
  late Directory directory;
  late CatalogDatabase database;
  late IdentityService identity;
  late AuthoringService authoring;
  late AssessmentService assessments;
  late ProgressService progress;
  late UserModel teacher;
  late UserModel student;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync(
      'flutter_quest_assessment_',
    );
    database = CatalogDatabase.open('${directory.path}/app.sqlite3');
    identity = IdentityService(
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
    teacher = teacherSession.user;
    student = await identity.createStudent(
      actor: teacher,
      username: 'student',
      displayName: 'Estudiante',
      password: 'student1234',
    );
    authoring = AuthoringService(SqliteAuthoringStore(database.database));
    assessments = AssessmentService(SqliteAssessmentStore(database.database));
    final progressStore = SqliteProgressStore(database.database);
    progress = ProgressService(progressStore, progressStore);
  });

  tearDown(() {
    database.close();
    directory.deleteSync(recursive: true);
  });

  test('bloquea por progreso y por ausencia de preguntas', () async {
    final initial = await assessments.overview(student);
    final world = initial.availability.first;
    expect(world.isAvailable, isFalse);
    expect(world.reason, contains('misiones'));
    expect(
      () => assessments.start(student, 'world_1'),
      throwsA(_code('assessment_locked')),
    );

    await _completeWorldOne(progress, student);
    final withoutQuestions = await assessments.overview(student);
    expect(withoutQuestions.availability.first.reason, contains('preguntas'));
    expect(
      () => assessments.start(student, 'world_1'),
      throwsA(_code('assessment_unavailable')),
    );
  });

  test(
    'califica exacto, aprueba con 80 y conserva snapshot e historial',
    () async {
      await _completeWorldOne(progress, student);
      final questions = <AuthoringQuestion>[];
      for (var index = 0; index < 5; index++) {
        questions.add(
          await authoring.saveQuestion(
            teacher,
            _question(
              prompt: 'Pregunta ${index + 1}',
              type: index == 1 ? QuestionType.multiple : QuestionType.single,
              explanation: 'Explicación original ${index + 1}',
            ),
          ),
        );
      }

      final attempt = await assessments.start(student, 'world_1');
      expect(attempt.questions, hasLength(5));
      expect(await assessments.start(student, 'world_1'), sameAttempt(attempt));
      final openJson = jsonEncode(attempt.toJson());
      expect(openJson, isNot(contains('isCorrect')));
      expect(openJson, isNot(contains('explanation')));

      final answers = <String, List<String>>{
        questions[0].id!: ['a'],
        questions[1].id!: ['a', 'b'],
        questions[2].id!: ['a'],
        questions[3].id!: ['a'],
        // La quinta queda vacía y cuenta como incorrecta.
      };
      final result = await assessments.submit(student, attempt.id, answers);
      expect(result.score, 80);
      expect(result.passed, isTrue);
      expect(result.correctAnswers, 4);
      expect(result.reviews.last.selectedOptionIds, isEmpty);
      expect(result.reviews[1].isCorrect, isTrue);
      expect(result.reviews.first.explanation, 'Explicación original 1');
      expect(
        () => assessments.submit(student, attempt.id, answers),
        throwsA(_code('attempt_submitted')),
      );

      await authoring.saveQuestion(
        teacher,
        _copyQuestion(questions.first, explanation: 'Explicación modificada'),
      );
      final restored = await assessments.loadResult(student, attempt.id);
      expect(restored.score, 80);
      expect(restored.reviews.first.explanation, 'Explicación original 1');

      final overview = await assessments.overview(student);
      expect(overview.history, hasLength(1));
      expect(overview.history.single.id, attempt.id);
      final repeated = await assessments.start(student, 'world_1');
      expect(repeated.id, isNot(attempt.id));
      final repeatedResult = await assessments.submit(
        student,
        repeated.id,
        const {},
      );
      expect(repeatedResult.score, 0);
      final repeatedHistory = (await assessments.overview(student)).history;
      expect(repeatedHistory, hasLength(2));
      expect(repeatedHistory.first.id, repeated.id);
      expect(repeatedHistory.last.id, attempt.id);
      expect(repeatedHistory.last.score, 80);
    },
  );

  test(
    'selección múltiple parcial falla y nota menor de 80 no aprueba',
    () async {
      await _completeWorldOne(progress, student);
      final question = await authoring.saveQuestion(
        teacher,
        _question(prompt: 'Múltiple', type: QuestionType.multiple),
      );
      final attempt = await assessments.start(student, 'world_1');
      final result = await assessments.submit(student, attempt.id, {
        question.id!: ['a'],
      });
      expect(result.score, 0);
      expect(result.passed, isFalse);
      expect(result.reviews.single.isCorrect, isFalse);
    },
  );

  test('aísla estudiantes y el informe docente aplica filtros', () async {
    await _completeWorldOne(progress, student);
    final question = await authoring.saveQuestion(
      teacher,
      _question(prompt: 'Informe'),
    );
    final attempt = await assessments.start(student, 'world_1');
    await assessments.submit(student, attempt.id, {
      question.id!: ['a'],
    });
    final other = await identity.createStudent(
      actor: teacher,
      username: 'other',
      displayName: 'Otro',
      password: 'student5678',
    );
    expect(
      () => assessments.loadResult(other, attempt.id),
      throwsA(_code('attempt_not_found')),
    );
    expect((await assessments.overview(other)).history, isEmpty);
    expect(() => assessments.report(student), throwsA(_code('forbidden')));

    final report = await assessments.report(
      teacher,
      studentId: student.id,
      worldId: 'world_1',
      topicId: 'dart_numeric_types',
    );
    expect(report.training, hasLength(1));
    expect(report.assessments, hasLength(1));
    expect(report.assessments.single.studentName, 'Estudiante');
    expect(
      report.assessments.single.topics.single.topicId,
      'dart_numeric_types',
    );
    final empty = await assessments.report(teacher, studentId: other.id);
    expect(empty.training, isEmpty);
    expect(empty.assessments, isEmpty);
  });
}

Future<void> _completeWorldOne(ProgressService progress, UserModel user) async {
  for (final mission in seedMissions.where(
    (item) => item.worldId == 'world_1',
  )) {
    final correct = mission.options.singleWhere((option) => option.isCorrect);
    await progress.checkAnswer(
      user: user,
      missionId: mission.id,
      optionId: correct.id,
      hintUsed: false,
    );
  }
}

AuthoringQuestion _question({
  required String prompt,
  QuestionType type = QuestionType.single,
  String explanation = 'Explicación',
}) => AuthoringQuestion(
  worldId: 'world_1',
  topicId: 'dart_numeric_types',
  prompt: prompt,
  type: type,
  explanation: explanation,
  status: ContentStatus.published,
  contentVersion: 1,
  options: [
    const AuthoringQuestionOption(id: 'a', text: 'A', isCorrect: true),
    AuthoringQuestionOption(
      id: 'b',
      text: 'B',
      isCorrect: type == QuestionType.multiple,
    ),
    const AuthoringQuestionOption(id: 'c', text: 'C', isCorrect: false),
  ],
);

AuthoringQuestion _copyQuestion(
  AuthoringQuestion source, {
  required String explanation,
}) => AuthoringQuestion(
  id: source.id,
  worldId: source.worldId,
  topicId: source.topicId,
  prompt: source.prompt,
  type: source.type,
  explanation: explanation,
  status: source.status,
  contentVersion: source.contentVersion,
  options: source.options,
);

Matcher _code(String code) =>
    isA<CatalogException>().having((error) => error.code, 'code', code);

Matcher sameAttempt(AssessmentAttempt expected) => isA<AssessmentAttempt>()
    .having((attempt) => attempt.id, 'id', expected.id)
    .having(
      (attempt) => attempt.questions.length,
      'questions',
      expected.questions.length,
    );
