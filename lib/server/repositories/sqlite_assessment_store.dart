import 'package:sqlite3/sqlite3.dart';

import '../../application/assessment/assessment_service.dart';
import '../../core/models/assessment_model.dart';
import '../../core/models/authoring_model.dart';
import '../../core/repositories/catalog_repository.dart';
import '../security/security_service.dart';

class SqliteAssessmentStore implements AssessmentStore {
  SqliteAssessmentStore(
    this._database, {
    SecureTokenService? tokenService,
    DateTime Function()? clock,
  }) : _tokenService = tokenService ?? SecureTokenService(),
       _clock = clock ?? DateTime.now;

  final Database _database;
  final SecureTokenService _tokenService;
  final DateTime Function() _clock;

  @override
  Future<AssessmentOverview> overview(String userId) async {
    final worlds = _database.select('''
      SELECT id, title FROM worlds
      WHERE status = 'published'
      ORDER BY sort_order
    ''');
    final availability = worlds.map((world) {
      final worldId = world['id']! as String;
      final missionCounts = _missionCounts(userId, worldId);
      final questionCount = _publishedQuestionCount(worldId);
      final attemptStats = _database
          .select(
            '''
        SELECT
          COUNT(*) AS completed_attempts,
          MAX(score) AS best_score
        FROM assessment_attempts
        WHERE user_id = ? AND world_id = ? AND status = 'submitted'
      ''',
            [userId, worldId],
          )
          .single;
      final open = _database.select(
        '''
        SELECT id FROM assessment_attempts
        WHERE user_id = ? AND world_id = ? AND status = 'open'
      ''',
        [userId, worldId],
      );
      final missionsComplete =
          missionCounts.total > 0 &&
          missionCounts.completed == missionCounts.total;
      final available = missionsComplete && questionCount > 0;
      final reason = !missionsComplete
          ? 'Completa todas las misiones publicadas del mundo.'
          : questionCount == 0
          ? 'El docente aún no ha publicado preguntas para este mundo.'
          : null;
      return AssessmentAvailability(
        worldId: worldId,
        worldTitle: world['title']! as String,
        isAvailable: available,
        reason: reason,
        publishedQuestions: questionCount,
        completedMissions: missionCounts.completed,
        totalMissions: missionCounts.total,
        completedAttempts: attemptStats['completed_attempts']! as int,
        bestScore: attemptStats['best_score'] as int?,
        openAttemptId: open.isEmpty ? null : open.single['id']! as String,
      );
    }).toList();
    return AssessmentOverview(
      availability: availability,
      history: _history(userId),
    );
  }

  @override
  Future<AssessmentAttempt> start(String userId, String worldId) async {
    String? attemptId;
    _database.execute('BEGIN IMMEDIATE');
    try {
      final existing = _database.select(
        '''
        SELECT id FROM assessment_attempts
        WHERE user_id = ? AND world_id = ? AND status = 'open'
      ''',
        [userId, worldId],
      );
      if (existing.isNotEmpty) {
        attemptId = existing.single['id']! as String;
      } else {
        final worldRows = _database.select(
          "SELECT id FROM worlds WHERE id = ? AND status = 'published'",
          [worldId],
        );
        if (worldRows.isEmpty) {
          throw const CatalogException(
            'world_not_found',
            'El mundo no existe o no está publicado.',
          );
        }
        final counts = _missionCounts(userId, worldId);
        if (counts.total == 0 || counts.completed != counts.total) {
          throw const CatalogException(
            'assessment_locked',
            'Completa todas las misiones antes de iniciar el parcial.',
          );
        }
        final questions = _publishedQuestions(worldId);
        if (questions.isEmpty) {
          throw const CatalogException(
            'assessment_unavailable',
            'No hay preguntas publicadas para este mundo.',
          );
        }
        attemptId = _tokenService.newId();
        final startedAt = _now();
        _database.execute(
          '''
          INSERT INTO assessment_attempts(
            id, user_id, world_id, status, started_at, total_questions
          ) VALUES (?, ?, ?, 'open', ?, ?)
        ''',
          [attemptId, userId, worldId, startedAt, questions.length],
        );
        for (var index = 0; index < questions.length; index++) {
          final question = questions[index];
          final questionId = question['id']! as String;
          _database.execute(
            '''
            INSERT INTO assessment_attempt_questions(
              attempt_id, question_id, position, topic_id, topic_title,
              prompt, question_type, explanation, content_version
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          ''',
            [
              attemptId,
              questionId,
              index + 1,
              question['topic_id'],
              question['topic_title'],
              question['prompt'],
              question['question_type'],
              question['explanation'],
              question['content_version'],
            ],
          );
          final options = _database.select(
            '''
            SELECT id, text, sort_order, is_correct
            FROM question_options
            WHERE question_id = ?
            ORDER BY sort_order
          ''',
            [questionId],
          );
          for (final option in options) {
            _database.execute(
              '''
              INSERT INTO assessment_attempt_options(
                attempt_id, question_id, option_id, text, sort_order, is_correct
              ) VALUES (?, ?, ?, ?, ?, ?)
            ''',
              [
                attemptId,
                questionId,
                option['id'],
                option['text'],
                option['sort_order'],
                option['is_correct'],
              ],
            );
          }
        }
      }
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
    return _openAttempt(userId, attemptId);
  }

  @override
  Future<AssessmentAttempt> loadAttempt(String userId, String attemptId) async {
    return _openAttempt(userId, attemptId);
  }

  @override
  Future<AssessmentResult> submit(
    String userId,
    String attemptId,
    Map<String, List<String>> answers,
  ) async {
    _database.execute('BEGIN IMMEDIATE');
    try {
      final attemptRows = _database.select(
        'SELECT * FROM assessment_attempts WHERE id = ? AND user_id = ?',
        [attemptId, userId],
      );
      if (attemptRows.isEmpty) throw _attemptNotFound;
      if (attemptRows.single['status'] != 'open') {
        throw const CatalogException(
          'attempt_submitted',
          'Este intento ya fue entregado.',
        );
      }
      final questions = _database.select(
        '''
        SELECT question_id, question_type
        FROM assessment_attempt_questions
        WHERE attempt_id = ?
        ORDER BY position
      ''',
        [attemptId],
      );
      final questionIds = questions
          .map((row) => row['question_id']! as String)
          .toSet();
      if (answers.keys.any((id) => !questionIds.contains(id))) {
        throw const CatalogException(
          'invalid_answers',
          'La entrega contiene una pregunta ajena al intento.',
        );
      }

      var correctAnswers = 0;
      for (final question in questions) {
        final questionId = question['question_id']! as String;
        final selected = answers[questionId] ?? const <String>[];
        if (question['question_type'] == 'single' && selected.length > 1) {
          throw const CatalogException(
            'invalid_answers',
            'Una pregunta de selección única admite una sola opción.',
          );
        }
        final optionRows = _database.select(
          '''
          SELECT option_id, is_correct
          FROM assessment_attempt_options
          WHERE attempt_id = ? AND question_id = ?
        ''',
          [attemptId, questionId],
        );
        final validIds = optionRows
            .map((row) => row['option_id']! as String)
            .toSet();
        if (selected.any((id) => !validIds.contains(id))) {
          throw const CatalogException(
            'invalid_answers',
            'La entrega contiene una opción ajena al intento.',
          );
        }
        for (final optionId in selected) {
          _database.execute(
            '''
            INSERT INTO assessment_answers(attempt_id, question_id, option_id)
            VALUES (?, ?, ?)
          ''',
            [attemptId, questionId, optionId],
          );
        }
        final expected = optionRows
            .where((row) => row['is_correct'] == 1)
            .map((row) => row['option_id']! as String)
            .toSet();
        if (selected.toSet().length == expected.length &&
            selected.toSet().containsAll(expected)) {
          correctAnswers++;
        }
      }
      final score = (100 * correctAnswers / questions.length).round();
      _database.execute(
        '''
        UPDATE assessment_attempts SET
          status = 'submitted', submitted_at = ?, score = ?, passed = ?,
          correct_answers = ?
        WHERE id = ? AND status = 'open'
      ''',
        [_now(), score, score >= 80 ? 1 : 0, correctAnswers, attemptId],
      );
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
    return _result(userId, attemptId);
  }

  @override
  Future<AssessmentResult> loadResult(String userId, String attemptId) async {
    return _result(userId, attemptId);
  }

  @override
  Future<TeacherReport> report({
    String? studentId,
    String? worldId,
    String? topicId,
  }) async {
    final trainingWhere = <String>[];
    final trainingArgs = <Object?>[];
    if (studentId != null) {
      trainingWhere.add('ta.user_id = ?');
      trainingArgs.add(studentId);
    }
    if (worldId != null) {
      trainingWhere.add('m.world_id = ?');
      trainingArgs.add(worldId);
    }
    if (topicId != null) {
      trainingWhere.add('m.topic_id = ?');
      trainingArgs.add(topicId);
    }
    final whereSql = trainingWhere.isEmpty
        ? ''
        : 'WHERE ${trainingWhere.join(' AND ')}';
    final training = _database
        .select('''
          SELECT ta.id, ta.user_id, u.display_name, m.world_id, w.title world_title,
            m.topic_id, t.title topic_title, m.title mission_title,
            ta.is_correct, ta.hint_used, ta.attempted_at
          FROM training_attempts ta
          JOIN users u ON u.id = ta.user_id
          JOIN missions m ON m.id = ta.mission_id
          JOIN worlds w ON w.id = m.world_id
          JOIN topics t ON t.id = m.topic_id
          $whereSql
          ORDER BY ta.attempted_at DESC
        ''', trainingArgs)
        .map(
          (row) => TrainingReportItem(
            id: row['id']! as String,
            userId: row['user_id']! as String,
            studentName: row['display_name']! as String,
            worldId: row['world_id']! as String,
            worldTitle: row['world_title']! as String,
            topicId: row['topic_id']! as String,
            topicTitle: row['topic_title']! as String,
            missionTitle: row['mission_title']! as String,
            isCorrect: row['is_correct'] == 1,
            hintUsed: row['hint_used'] == 1,
            occurredAt: DateTime.parse(row['attempted_at']! as String),
          ),
        )
        .toList();

    final assessmentWhere = <String>["aa.status = 'submitted'"];
    final assessmentArgs = <Object?>[];
    if (studentId != null) {
      assessmentWhere.add('aa.user_id = ?');
      assessmentArgs.add(studentId);
    }
    if (worldId != null) {
      assessmentWhere.add('aa.world_id = ?');
      assessmentArgs.add(worldId);
    }
    if (topicId != null) {
      assessmentWhere.add(
        'EXISTS (SELECT 1 FROM assessment_attempt_questions aq '
        'WHERE aq.attempt_id = aa.id AND aq.topic_id = ?)',
      );
      assessmentArgs.add(topicId);
    }
    final assessmentRows = _database.select('''
      SELECT aa.*, u.display_name, w.title world_title
      FROM assessment_attempts aa
      JOIN users u ON u.id = aa.user_id
      JOIN worlds w ON w.id = aa.world_id
      WHERE ${assessmentWhere.join(' AND ')}
      ORDER BY aa.submitted_at DESC
    ''', assessmentArgs);
    final assessments = assessmentRows.map((row) {
      final id = row['id']! as String;
      var topics = _topicScores(id);
      if (topicId != null) {
        topics = topics.where((topic) => topic.topicId == topicId).toList();
      }
      return AssessmentReportItem(
        id: id,
        userId: row['user_id']! as String,
        studentName: row['display_name']! as String,
        worldId: row['world_id']! as String,
        worldTitle: row['world_title']! as String,
        score: row['score']! as int,
        passed: row['passed'] == 1,
        submittedAt: DateTime.parse(row['submitted_at']! as String),
        topics: topics,
      );
    }).toList();
    return TeacherReport(training: training, assessments: assessments);
  }

  AssessmentAttempt _openAttempt(String userId, String attemptId) {
    final rows = _database.select(
      '''
      SELECT aa.*, w.title world_title
      FROM assessment_attempts aa
      JOIN worlds w ON w.id = aa.world_id
      WHERE aa.id = ? AND aa.user_id = ?
    ''',
      [attemptId, userId],
    );
    if (rows.isEmpty) throw _attemptNotFound;
    final row = rows.single;
    if (row['status'] != 'open') {
      throw const CatalogException(
        'attempt_submitted',
        'Este intento ya fue entregado.',
      );
    }
    return AssessmentAttempt(
      id: attemptId,
      worldId: row['world_id']! as String,
      worldTitle: row['world_title']! as String,
      startedAt: DateTime.parse(row['started_at']! as String),
      questions: _database
          .select(
            '''
            SELECT * FROM assessment_attempt_questions
            WHERE attempt_id = ? ORDER BY position
          ''',
            [attemptId],
          )
          .map(
            (question) => AssessmentQuestion(
              id: question['question_id']! as String,
              topicId: question['topic_id']! as String,
              topicTitle: question['topic_title']! as String,
              prompt: question['prompt']! as String,
              type: QuestionType.fromWireName(
                question['question_type']! as String,
              ),
              contentVersion: question['content_version']! as int,
              options: _options(attemptId, question['question_id']! as String),
            ),
          )
          .toList(),
    );
  }

  AssessmentResult _result(String userId, String attemptId) {
    final rows = _database.select(
      '''
      SELECT aa.*, w.title world_title
      FROM assessment_attempts aa
      JOIN worlds w ON w.id = aa.world_id
      WHERE aa.id = ? AND aa.user_id = ?
    ''',
      [attemptId, userId],
    );
    if (rows.isEmpty) throw _attemptNotFound;
    final attempt = rows.single;
    if (attempt['status'] != 'submitted') {
      throw const CatalogException(
        'attempt_open',
        'Entrega el intento antes de consultar su resultado.',
      );
    }
    final reviews = _database
        .select(
          '''
          SELECT * FROM assessment_attempt_questions
          WHERE attempt_id = ? ORDER BY position
        ''',
          [attemptId],
        )
        .map((question) {
          final questionId = question['question_id']! as String;
          final options = _optionRows(attemptId, questionId);
          final selected = _selected(attemptId, questionId);
          final correct = options
              .where((row) => row['is_correct'] == 1)
              .map((row) => row['option_id']! as String)
              .toList();
          final isCorrect =
              selected.toSet().length == correct.length &&
              selected.toSet().containsAll(correct);
          return AssessmentReview(
            questionId: questionId,
            topicId: question['topic_id']! as String,
            prompt: question['prompt']! as String,
            type: QuestionType.fromWireName(
              question['question_type']! as String,
            ),
            selectedOptionIds: selected,
            correctOptionIds: correct,
            options: options
                .map(
                  (row) => AssessmentOption(
                    id: row['option_id']! as String,
                    text: row['text']! as String,
                  ),
                )
                .toList(),
            explanation: question['explanation']! as String,
            isCorrect: isCorrect,
          );
        })
        .toList();
    return AssessmentResult(
      attemptId: attemptId,
      worldId: attempt['world_id']! as String,
      worldTitle: attempt['world_title']! as String,
      score: attempt['score']! as int,
      passed: attempt['passed'] == 1,
      correctAnswers: attempt['correct_answers']! as int,
      totalQuestions: attempt['total_questions']! as int,
      submittedAt: DateTime.parse(attempt['submitted_at']! as String),
      topics: _topicScores(attemptId),
      reviews: reviews,
    );
  }

  List<TopicAssessmentScore> _topicScores(String attemptId) {
    final questions = _database.select(
      '''
      SELECT question_id, topic_id, topic_title
      FROM assessment_attempt_questions
      WHERE attempt_id = ? ORDER BY position
    ''',
      [attemptId],
    );
    final scores = <String, ({String title, int correct, int total})>{};
    for (final question in questions) {
      final questionId = question['question_id']! as String;
      final expected = _optionRows(attemptId, questionId)
          .where((row) => row['is_correct'] == 1)
          .map((row) => row['option_id']! as String)
          .toSet();
      final selected = _selected(attemptId, questionId).toSet();
      final correct =
          selected.length == expected.length && selected.containsAll(expected);
      final topicId = question['topic_id']! as String;
      final current = scores[topicId];
      scores[topicId] = (
        title: question['topic_title']! as String,
        correct: (current?.correct ?? 0) + (correct ? 1 : 0),
        total: (current?.total ?? 0) + 1,
      );
    }
    return scores.entries
        .map(
          (entry) => TopicAssessmentScore(
            topicId: entry.key,
            topicTitle: entry.value.title,
            correctAnswers: entry.value.correct,
            totalQuestions: entry.value.total,
          ),
        )
        .toList();
  }

  List<AssessmentHistoryItem> _history(String userId) {
    return _database
        .select(
          '''
          SELECT aa.*, w.title world_title
          FROM assessment_attempts aa
          JOIN worlds w ON w.id = aa.world_id
          WHERE aa.user_id = ? AND aa.status = 'submitted'
          ORDER BY aa.submitted_at DESC
        ''',
          [userId],
        )
        .map(
          (row) => AssessmentHistoryItem(
            id: row['id']! as String,
            worldId: row['world_id']! as String,
            worldTitle: row['world_title']! as String,
            startedAt: DateTime.parse(row['started_at']! as String),
            submittedAt: DateTime.parse(row['submitted_at']! as String),
            score: row['score']! as int,
            passed: row['passed'] == 1,
            correctAnswers: row['correct_answers']! as int,
            totalQuestions: row['total_questions']! as int,
          ),
        )
        .toList();
  }

  ({int completed, int total}) _missionCounts(String userId, String worldId) {
    final row = _database
        .select(
          '''
      SELECT
        COUNT(m.id) AS total,
        SUM(CASE WHEN mp.mission_id IS NULL THEN 0 ELSE 1 END) AS completed
      FROM missions m
      JOIN topics t ON t.id = m.topic_id AND t.status = 'published'
      LEFT JOIN mission_progress mp
        ON mp.mission_id = m.id AND mp.user_id = ?
      WHERE m.world_id = ? AND m.status = 'published'
    ''',
          [userId, worldId],
        )
        .single;
    return (
      completed: (row['completed'] as int?) ?? 0,
      total: row['total']! as int,
    );
  }

  int _publishedQuestionCount(String worldId) =>
      _publishedQuestions(worldId).length;

  ResultSet _publishedQuestions(String worldId) => _database.select(
    '''
    SELECT q.*, t.title topic_title
    FROM questions q
    JOIN topics t ON t.id = q.topic_id AND t.world_id = q.world_id
    JOIN worlds w ON w.id = q.world_id
    WHERE q.world_id = ? AND q.status = 'published'
      AND t.status = 'published' AND w.status = 'published'
    ORDER BY q.created_at, q.id
  ''',
    [worldId],
  );

  List<AssessmentOption> _options(String attemptId, String questionId) =>
      _optionRows(attemptId, questionId)
          .map(
            (row) => AssessmentOption(
              id: row['option_id']! as String,
              text: row['text']! as String,
            ),
          )
          .toList();

  ResultSet _optionRows(String attemptId, String questionId) =>
      _database.select(
        '''
        SELECT option_id, text, is_correct
        FROM assessment_attempt_options
        WHERE attempt_id = ? AND question_id = ?
        ORDER BY sort_order
      ''',
        [attemptId, questionId],
      );

  List<String> _selected(String attemptId, String questionId) => _database
      .select(
        '''
        SELECT option_id FROM assessment_answers
        WHERE attempt_id = ? AND question_id = ?
        ORDER BY option_id
      ''',
        [attemptId, questionId],
      )
      .map((row) => row['option_id']! as String)
      .toList();

  String _now() => _clock().toUtc().toIso8601String();

  static const _attemptNotFound = CatalogException(
    'attempt_not_found',
    'El intento no existe o pertenece a otro estudiante.',
  );
}
