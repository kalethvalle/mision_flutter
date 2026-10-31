import 'package:mision_flutter/core/models/answer_check_result.dart';
import 'package:mision_flutter/core/models/assessment_model.dart';
import 'package:mision_flutter/core/models/authoring_model.dart';
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
  late final List<AuthoringWorld> _authoringWorlds = seedWorlds
      .map(
        (world) => AuthoringWorld(
          id: world.id,
          title: world.title,
          description: world.description,
          iconKey: world.iconKey,
          colorHex: world.colorHex,
          sortOrder: world.sortOrder,
          status: ContentStatus.published,
        ),
      )
      .toList();
  late final List<AuthoringTopic> _authoringTopics = seedTopics
      .map(
        (topic) => AuthoringTopic(
          id: topic.id,
          worldId: topic.worldId,
          title: topic.title,
          description: topic.description,
          sortOrder: topic.sortOrder,
          status: ContentStatus.published,
        ),
      )
      .toList();
  late final List<AuthoringMission> _authoringMissions = seedMissions
      .map(
        (mission) => AuthoringMission(
          id: mission.id,
          worldId: mission.worldId,
          topicId: mission.topicId,
          title: mission.title,
          description: mission.description,
          paragraphs: mission.paragraphs,
          instructions: mission.instructions,
          hint: mission.hint,
          category: MissionCategory.fromWireName(mission.category),
          codeTemplate: mission.codeTemplate,
          targetPlaceholder: mission.targetPlaceholder,
          previewType: mission.previewType,
          sortOrder: mission.sortOrder,
          status: ContentStatus.published,
          contentVersion: 1,
          options: mission.options
              .map(
                (option) => AuthoringMissionOption(
                  id: option.id,
                  label: option.label,
                  codeSnippet: option.codeSnippet,
                  isCorrect: option.isCorrect,
                ),
              )
              .toList(),
        ),
      )
      .toList();
  final List<AuthoringQuestion> _authoringQuestions = [];
  AssessmentAttempt? _openAssessment;
  final List<AssessmentHistoryItem> _assessmentHistory = [];
  final Map<String, AssessmentResult> _assessmentResults = {};
  final Map<String, Set<String>> _assessmentCorrect = {};
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

  @override
  Future<AuthoringCatalog> getAuthoringCatalog() async => AuthoringCatalog(
    worlds: List.unmodifiable(_authoringWorlds),
    topics: List.unmodifiable(_authoringTopics),
    missions: List.unmodifiable(_authoringMissions),
    questions: List.unmodifiable(_authoringQuestions),
    previewTypes: const [
      'dart.variables',
      'dart.final',
      'dart.arrow',
      'dart.lists',
      'dart.null_safety',
      'flutter.row',
      'flutter.column',
      'flutter.padding',
      'flutter.stack',
    ],
  );

  @override
  Future<AuthoringWorld> saveWorld(AuthoringWorld world) async {
    final saved = AuthoringWorld(
      id: world.id ?? 'world_${_authoringWorlds.length + 1}',
      title: world.title,
      description: world.description,
      iconKey: world.iconKey,
      colorHex: world.colorHex,
      sortOrder: world.sortOrder,
      status: world.status,
    );
    _replace(_authoringWorlds, saved.id!, saved, (item) => item.id!);
    return saved;
  }

  @override
  Future<AuthoringTopic> saveTopic(AuthoringTopic topic) async {
    final saved = AuthoringTopic(
      id: topic.id ?? 'topic_${_authoringTopics.length + 1}',
      worldId: topic.worldId,
      title: topic.title,
      description: topic.description,
      sortOrder: topic.sortOrder,
      status: topic.status,
    );
    _replace(_authoringTopics, saved.id!, saved, (item) => item.id!);
    return saved;
  }

  @override
  Future<AuthoringMission> saveMission(AuthoringMission mission) async {
    final saved = AuthoringMission(
      id: mission.id ?? 'mission_${_authoringMissions.length + 1}',
      worldId: mission.worldId,
      topicId: mission.topicId,
      title: mission.title,
      description: mission.description,
      paragraphs: mission.paragraphs,
      instructions: mission.instructions,
      hint: mission.hint,
      category: mission.category,
      codeTemplate: mission.codeTemplate,
      targetPlaceholder: mission.targetPlaceholder,
      previewType: mission.previewType,
      sortOrder: mission.sortOrder,
      status: mission.status,
      contentVersion: mission.id == null ? 1 : mission.contentVersion + 1,
      options: mission.options,
    );
    _replace(_authoringMissions, saved.id!, saved, (item) => item.id!);
    return saved;
  }

  @override
  Future<AuthoringQuestion> saveQuestion(AuthoringQuestion question) async {
    final saved = AuthoringQuestion(
      id: question.id ?? 'question_${_authoringQuestions.length + 1}',
      worldId: question.worldId,
      topicId: question.topicId,
      prompt: question.prompt,
      type: question.type,
      explanation: question.explanation,
      status: question.status,
      contentVersion: question.id == null ? 1 : question.contentVersion + 1,
      options: question.options,
    );
    _replace(_authoringQuestions, saved.id!, saved, (item) => item.id!);
    return saved;
  }

  void addPublishedQuestion({
    String id = 'question_1',
    String worldId = 'world_1',
    String topicId = 'dart_numeric_types',
    QuestionType type = QuestionType.single,
  }) {
    _authoringQuestions.add(
      AuthoringQuestion(
        id: id,
        worldId: worldId,
        topicId: topicId,
        prompt: 'Pregunta de prueba',
        type: type,
        explanation: 'Explicación de prueba.',
        status: ContentStatus.published,
        contentVersion: 1,
        options: const [
          AuthoringQuestionOption(id: 'a', text: 'Correcta', isCorrect: true),
          AuthoringQuestionOption(
            id: 'b',
            text: 'Incorrecta',
            isCorrect: false,
          ),
        ],
      ),
    );
  }

  @override
  Future<AssessmentOverview> getAssessmentOverview() async {
    final availability = seedWorlds.map((world) {
      final missions = seedMissions
          .where((mission) => mission.worldId == world.id)
          .toList();
      final completed = missions
          .where((mission) => completedMissionIds.contains(mission.id))
          .length;
      final questions = _authoringQuestions
          .where(
            (question) =>
                question.worldId == world.id &&
                question.status == ContentStatus.published,
          )
          .length;
      final available = completed == missions.length && questions > 0;
      return AssessmentAvailability(
        worldId: world.id,
        worldTitle: world.title,
        isAvailable: available,
        reason: completed < missions.length
            ? 'Completa todas las misiones publicadas del mundo.'
            : questions == 0
            ? 'El docente aún no ha publicado preguntas para este mundo.'
            : null,
        publishedQuestions: questions,
        completedMissions: completed,
        totalMissions: missions.length,
        completedAttempts: _assessmentHistory
            .where((item) => item.worldId == world.id)
            .length,
        bestScore: _assessmentHistory
            .where((item) => item.worldId == world.id)
            .map((item) => item.score)
            .fold<int?>(
              null,
              (best, score) => best == null || score > best ? score : best,
            ),
        openAttemptId: _openAssessment?.worldId == world.id
            ? _openAssessment?.id
            : null,
      );
    }).toList();
    return AssessmentOverview(
      availability: availability,
      history: List.unmodifiable(_assessmentHistory),
    );
  }

  @override
  Future<AssessmentAttempt> startAssessment(String worldId) async {
    if (_openAssessment?.worldId == worldId) return _openAssessment!;
    final overview = await getAssessmentOverview();
    final availability = overview.availability.singleWhere(
      (item) => item.worldId == worldId,
    );
    if (!availability.isAvailable) {
      throw CatalogException('assessment_locked', availability.reason!);
    }
    final questions = _authoringQuestions
        .where(
          (question) =>
              question.worldId == worldId &&
              question.status == ContentStatus.published,
        )
        .map((question) {
          _assessmentCorrect[question.id!] = question.options
              .where((option) => option.isCorrect)
              .map((option) => option.id)
              .toSet();
          final topic = seedTopics.singleWhere(
            (item) => item.id == question.topicId,
          );
          return AssessmentQuestion(
            id: question.id!,
            topicId: question.topicId,
            topicTitle: topic.title,
            prompt: question.prompt,
            type: question.type,
            contentVersion: question.contentVersion,
            options: question.options
                .map(
                  (option) =>
                      AssessmentOption(id: option.id, text: option.text),
                )
                .toList(),
          );
        })
        .toList();
    final world = seedWorlds.singleWhere((item) => item.id == worldId);
    _openAssessment = AssessmentAttempt(
      id: 'attempt_${_assessmentHistory.length + 1}',
      worldId: worldId,
      worldTitle: world.title,
      startedAt: DateTime.utc(2026, 10, 30, 12),
      questions: questions,
    );
    return _openAssessment!;
  }

  @override
  Future<AssessmentAttempt> getAssessmentAttempt(String attemptId) async {
    if (_openAssessment?.id != attemptId) {
      throw const CatalogException('attempt_not_found', 'Intento inexistente.');
    }
    return _openAssessment!;
  }

  @override
  Future<AssessmentResult> submitAssessment(
    String attemptId,
    Map<String, List<String>> answers,
  ) async {
    final attempt = await getAssessmentAttempt(attemptId);
    final reviews = attempt.questions.map((question) {
      final selected = answers[question.id] ?? const <String>[];
      final correct = _assessmentCorrect[question.id] ?? const <String>{};
      final isCorrect =
          selected.toSet().length == correct.length &&
          selected.toSet().containsAll(correct);
      final source = _authoringQuestions.singleWhere(
        (item) => item.id == question.id,
      );
      return AssessmentReview(
        questionId: question.id,
        topicId: question.topicId,
        prompt: question.prompt,
        type: question.type,
        selectedOptionIds: selected,
        correctOptionIds: correct.toList(),
        options: question.options,
        explanation: source.explanation,
        isCorrect: isCorrect,
      );
    }).toList();
    final correctCount = reviews.where((review) => review.isCorrect).length;
    final score = (100 * correctCount / reviews.length).round();
    final submittedAt = DateTime.utc(
      2026,
      10,
      30,
      12,
      _assessmentHistory.length + 1,
    );
    final topics = <TopicAssessmentScore>[];
    for (final topicId in reviews.map((review) => review.topicId).toSet()) {
      final scoped = reviews
          .where((review) => review.topicId == topicId)
          .toList();
      final title = attempt.questions
          .firstWhere((item) => item.topicId == topicId)
          .topicTitle;
      topics.add(
        TopicAssessmentScore(
          topicId: topicId,
          topicTitle: title,
          correctAnswers: scoped.where((review) => review.isCorrect).length,
          totalQuestions: scoped.length,
        ),
      );
    }
    final result = AssessmentResult(
      attemptId: attemptId,
      worldId: attempt.worldId,
      worldTitle: attempt.worldTitle,
      score: score,
      passed: score >= 80,
      correctAnswers: correctCount,
      totalQuestions: reviews.length,
      submittedAt: submittedAt,
      topics: topics,
      reviews: reviews,
    );
    _assessmentResults[attemptId] = result;
    _assessmentHistory.insert(
      0,
      AssessmentHistoryItem(
        id: attemptId,
        worldId: attempt.worldId,
        worldTitle: attempt.worldTitle,
        startedAt: attempt.startedAt,
        submittedAt: submittedAt,
        score: score,
        passed: result.passed,
        correctAnswers: correctCount,
        totalQuestions: reviews.length,
      ),
    );
    _openAssessment = null;
    return result;
  }

  @override
  Future<AssessmentResult> getAssessmentResult(String attemptId) async {
    final result = _assessmentResults[attemptId];
    if (result == null) {
      throw const CatalogException('attempt_not_found', 'Intento inexistente.');
    }
    return result;
  }

  @override
  Future<TeacherReport> getTeacherReport({
    String? studentId,
    String? worldId,
    String? topicId,
  }) async => const TeacherReport(training: [], assessments: []);
}

void _replace<T>(
  List<T> items,
  String id,
  T value,
  String Function(T item) idOf,
) {
  final index = items.indexWhere((item) => idOf(item) == id);
  if (index < 0) {
    items.add(value);
  } else {
    items[index] = value;
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
