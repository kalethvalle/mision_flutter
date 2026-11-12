import 'dart:async';

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
  final StreamController<AssessmentAttemptEvent> _events =
      StreamController<AssessmentAttemptEvent>.broadcast();

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
      final session = _activeSession(worldId);
      final missionsComplete =
          missionCounts.total > 0 &&
          missionCounts.completed == missionCounts.total;
      final sessionAvailable =
          session != null &&
          DateTime.parse(session['closes_at']! as String).isAfter(_clock());
      final available =
          missionsComplete && questionCount > 0 && sessionAvailable;
      final reason = !missionsComplete
          ? 'Completa todas las misiones publicadas del mundo.'
          : questionCount == 0
          ? 'El docente aún no ha publicado preguntas para este mundo.'
          : !sessionAvailable
          ? 'El docente aún no ha activado el parcial de este mundo.'
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
        activeSessionId: session?['id'] as String?,
        sessionClosesAt: session == null
            ? null
            : DateTime.parse(session['closes_at']! as String),
        durationMinutes: session?['duration_minutes'] as int?,
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
        final session = _activeSession(worldId);
        if (session == null ||
            !DateTime.parse(session['closes_at']! as String)
                .isAfter(_clock())) {
          throw const CatalogException(
            'assessment_inactive',
            'El docente debe activar la sesión del parcial.',
          );
        }
        attemptId = _tokenService.newId();
        final startedAt = _now();
        _database.execute(
          '''
          INSERT INTO assessment_attempts(
            id, user_id, world_id, status, session_id, started_at, deadline_at,
            total_questions
          ) VALUES (?, ?, ?, 'open', ?, ?, ?, ?)
        ''',
          [
            attemptId,
            userId,
            worldId,
            session['id'],
            startedAt,
            session['closes_at'],
            questions.length,
          ],
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
        _recordEvent(
          session['id']! as String,
          attemptId: attemptId,
          userId: userId,
          type: 'started',
          message: 'Inició el parcial.',
          answeredQuestions: 0,
          totalQuestions: questions.length,
        );
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
        if (attemptRows.single['status'] == 'submitted') {
          throw const CatalogException(
            'attempt_submitted',
            'Este intento ya fue entregado.',
          );
        }
        throw const CatalogException(
          'attempt_annulled',
          'Este intento ya no está abierto.',
        );
      }
      final deadline = attemptRows.single['deadline_at'] as String?;
      if (deadline != null && !DateTime.parse(deadline).isAfter(_clock())) {
        _annulAttempt(
          attemptId,
          'El tiempo del parcial finalizó.',
          type: 'expired',
        );
        throw const CatalogException(
          'attempt_annulled',
          'El tiempo del parcial finalizó.',
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
      _database.execute(
        'DELETE FROM assessment_draft_answers WHERE attempt_id = ?',
        [attemptId],
      );
      final sessionId = attemptRows.single['session_id'] as String?;
      if (sessionId != null) {
        _recordEvent(
          sessionId,
          attemptId: attemptId,
          userId: userId,
          type: 'submitted',
          message: 'Entregó el parcial.',
          answeredQuestions: answers.values
              .where((items) => items.isNotEmpty)
              .length,
          totalQuestions: questions.length,
          score: score,
        );
      }
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
    return _result(userId, attemptId);
  }

  @override
  Future<void> saveDraftAnswers(
    String userId,
    String attemptId,
    Map<String, List<String>> answers,
  ) async {
    _database.execute('BEGIN IMMEDIATE');
    try {
      final attempt = _openAttemptRow(userId, attemptId);
      final questions = _database.select(
        '''
        SELECT question_id, question_type
        FROM assessment_attempt_questions
        WHERE attempt_id = ?
      ''',
        [attemptId],
      );
      final questionIds = questions
          .map((row) => row['question_id']! as String)
          .toSet();
      if (answers.keys.any((id) => !questionIds.contains(id))) {
        throw const CatalogException(
          'invalid_answers',
          'La respuesta parcial contiene una pregunta ajena al intento.',
        );
      }
      _database.execute(
        'DELETE FROM assessment_draft_answers WHERE attempt_id = ?',
        [attemptId],
      );
      final now = _now();
      for (final entry in answers.entries) {
        final optionRows = _optionRows(attemptId, entry.key);
        final validIds = optionRows
            .map((row) => row['option_id']! as String)
            .toSet();
        if (entry.value.any((id) => !validIds.contains(id))) {
          throw const CatalogException(
            'invalid_answers',
            'La respuesta parcial contiene una opción ajena al intento.',
          );
        }
        for (final optionId in entry.value.toSet()) {
          _database.execute(
            '''
            INSERT INTO assessment_draft_answers(
              attempt_id, question_id, option_id, updated_at
            ) VALUES (?, ?, ?, ?)
          ''',
            [attemptId, entry.key, optionId, now],
          );
        }
      }
      final answered = answers.values.where((items) => items.isNotEmpty).length;
      final sessionId = attempt['session_id'] as String?;
      if (sessionId != null) {
        _recordEvent(
          sessionId,
          attemptId: attemptId,
          userId: userId,
          type: 'progress',
          message: 'Actualizó respuestas.',
          answeredQuestions: answered,
          totalQuestions: questions.length,
        );
      }
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  @override
  Future<AssessmentAttempt> recordIncident(
    String userId,
    String attemptId, {
    required String type,
    required String message,
  }) async {
    _database.execute('BEGIN IMMEDIATE');
    try {
      final attempt = _openAttemptRow(userId, attemptId);
      final sessionId = attempt['session_id'] as String?;
      if (sessionId == null) throw _attemptNotFound;
      _recordEvent(
        sessionId,
        attemptId: attemptId,
        userId: userId,
        type: type,
        message: message,
        answeredQuestions: _answeredDraftCount(attemptId),
        totalQuestions: attempt['total_questions']! as int,
      );
      final settings = _settingsFor(attempt['world_id']! as String);
      final incidents = _incidentCount(attemptId);
      if (settings.strictMode && incidents >= settings.maxIncidents) {
        _annulAttempt(
          attemptId,
          'Superó el límite de incidentes del parcial.',
          type: 'annulled',
        );
      }
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
    return _openAttempt(userId, attemptId);
  }

  @override
  Future<AssessmentResult> loadResult(String userId, String attemptId) async {
    return _result(userId, attemptId);
  }

  @override
  Future<AssessmentSessionOverview> sessionOverview() async {
    final settings = _database
        .select('''
          SELECT s.*, w.title world_title
          FROM assessment_world_settings s
          JOIN worlds w ON w.id = s.world_id
          ORDER BY w.sort_order
        ''')
        .map((row) => _settingsFor(row['world_id']! as String))
        .toList();
    final sessions = _database
        .select('''
          SELECT s.*, w.title world_title
          FROM assessment_sessions s
          JOIN worlds w ON w.id = s.world_id
          ORDER BY s.opened_at DESC
          LIMIT 12
        ''')
        .map(_sessionFromRow)
        .toList();
    return AssessmentSessionOverview(settings: settings, sessions: sessions);
  }

  @override
  Future<AssessmentWorldSettings> saveSettings(
    AssessmentWorldSettings settings,
  ) async {
    _database.execute(
      '''
      INSERT INTO assessment_world_settings(
        world_id, duration_minutes, fullscreen_required, max_incidents,
        return_grace_seconds, strict_mode, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(world_id) DO UPDATE SET
        duration_minutes = excluded.duration_minutes,
        fullscreen_required = excluded.fullscreen_required,
        max_incidents = excluded.max_incidents,
        return_grace_seconds = excluded.return_grace_seconds,
        strict_mode = excluded.strict_mode,
        updated_at = excluded.updated_at
    ''',
      [
        settings.worldId,
        settings.durationMinutes,
        settings.fullscreenRequired ? 1 : 0,
        settings.maxIncidents,
        settings.returnGraceSeconds,
        settings.strictMode ? 1 : 0,
        _now(),
      ],
    );
    return _settingsFor(settings.worldId);
  }

  @override
  Future<AssessmentSession> openSession(
    String teacherId,
    String worldId,
  ) async {
    _database.execute('BEGIN IMMEDIATE');
    late String sessionId;
    try {
      final world = _database.select(
        "SELECT title FROM worlds WHERE id = ? AND status = 'published'",
        [worldId],
      );
      if (world.isEmpty) {
        throw const CatalogException(
          'world_not_found',
          'El mundo no existe o no está publicado.',
        );
      }
      final existing = _activeSession(worldId);
      if (existing != null) {
        sessionId = existing['id']! as String;
      } else {
        final settings = _settingsFor(worldId);
        final openedAt = _clock().toUtc();
        final closesAt = openedAt.add(
          Duration(minutes: settings.durationMinutes),
        );
        sessionId = _tokenService.newId();
        _database.execute(
          '''
          INSERT INTO assessment_sessions(
            id, world_id, opened_by, status, opened_at, closes_at,
            duration_minutes, fullscreen_required, max_incidents,
            return_grace_seconds, strict_mode
          ) VALUES (?, ?, ?, 'open', ?, ?, ?, ?, ?, ?, ?)
        ''',
          [
            sessionId,
            worldId,
            teacherId,
            openedAt.toIso8601String(),
            closesAt.toIso8601String(),
            settings.durationMinutes,
            settings.fullscreenRequired ? 1 : 0,
            settings.maxIncidents,
            settings.returnGraceSeconds,
            settings.strictMode ? 1 : 0,
          ],
        );
        _recordEvent(
          sessionId,
          type: 'session_opened',
          message: 'El docente activó el parcial.',
        );
      }
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
    return _sessionById(sessionId);
  }

  @override
  Future<AssessmentSession> closeSession(
    String teacherId,
    String sessionId,
  ) async {
    _database.execute('BEGIN IMMEDIATE');
    try {
      _database.execute(
        '''
        UPDATE assessment_sessions
        SET status = 'closed', closed_at = ?
        WHERE id = ? AND status = 'open'
      ''',
        [_now(), sessionId],
      );
      _recordEvent(
        sessionId,
        type: 'session_closed',
        message: 'El docente cerró el parcial.',
      );
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
    return _sessionById(sessionId);
  }

  @override
  Future<AssessmentSession> reactivateAttempt(
    String teacherId,
    String attemptId, {
    required String reason,
  }) async {
    _database.execute('BEGIN IMMEDIATE');
    late String sessionId;
    try {
      final rows = _database.select(
        'SELECT * FROM assessment_attempts WHERE id = ?',
        [attemptId],
      );
      if (rows.isEmpty) throw _attemptNotFound;
      final row = rows.single;
      if (row['session_id'] == null) {
        throw const CatalogException(
          'assessment_inactive',
          'Este intento no pertenece a una sesión controlada.',
        );
      }
      sessionId = row['session_id']! as String;
      _database.execute(
        '''
        UPDATE assessment_attempts
        SET status = 'open', annulled_at = NULL, annulled_reason = NULL,
          reactivation_count = reactivation_count + 1
        WHERE id = ?
      ''',
        [attemptId],
      );
      _recordEvent(
        sessionId,
        attemptId: attemptId,
        userId: row['user_id']! as String,
        type: 'reactivated',
        message: reason,
      );
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
    return _sessionById(sessionId);
  }

  @override
  Future<AssessmentDetailReport> detailReport(String attemptId) async {
    final row = _reportRows(attemptId: attemptId).singleOrNull;
    if (row == null) throw _attemptNotFound;
    return AssessmentDetailReport(
      attempt: _reportItem(row),
      questions: _questionReports(attemptId),
      events: _eventsForAttempt(attemptId),
    );
  }

  @override
  Stream<AssessmentAttemptEvent> streamSessionEvents(String sessionId) async* {
    for (final event in _eventsForSession(sessionId)) {
      yield event;
    }
    yield* _events.stream.where((event) => event.sessionId == sessionId);
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

    final assessmentWhere = <String>["aa.status IN ('submitted', 'annulled')"];
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
    final assessmentRows = _reportRows(
      whereSql: assessmentWhere.join(' AND '),
      args: assessmentArgs,
    );
    final assessments = assessmentRows.map((row) {
      var item = _reportItem(row);
      if (topicId != null) {
        item = AssessmentReportItem(
          id: item.id,
          userId: item.userId,
          studentName: item.studentName,
          worldId: item.worldId,
          worldTitle: item.worldTitle,
          score: item.score,
          passed: item.passed,
          status: item.status,
          startedAt: item.startedAt,
          deadlineAt: item.deadlineAt,
          submittedAt: item.submittedAt,
          durationSeconds: item.durationSeconds,
          incidents: item.incidents,
          reactivationCount: item.reactivationCount,
          topics: item.topics
              .where((topic) => topic.topicId == topicId)
              .toList(),
        );
      }
      return item;
    }).toList();
    return TeacherReport(training: training, assessments: assessments);
  }

  ResultSet _reportRows({
    String whereSql = 'aa.id = ?',
    List<Object?>? args,
    String? attemptId,
  }) {
    final effectiveArgs = attemptId == null ? (args ?? const []) : [attemptId];
    return _database.select('''
      SELECT aa.*, u.display_name, w.title world_title
      FROM assessment_attempts aa
      JOIN users u ON u.id = aa.user_id
      JOIN worlds w ON w.id = aa.world_id
      WHERE $whereSql
      ORDER BY COALESCE(aa.submitted_at, aa.annulled_at, aa.started_at) DESC
    ''', effectiveArgs);
  }

  AssessmentReportItem _reportItem(Row row) {
    final id = row['id']! as String;
    final startedAt = DateTime.parse(row['started_at']! as String);
    final submittedAt = row['submitted_at'] == null
        ? null
        : DateTime.parse(row['submitted_at']! as String);
    final endAt =
        submittedAt ??
        (row['annulled_at'] == null
            ? _clock()
            : DateTime.parse(row['annulled_at']! as String));
    return AssessmentReportItem(
      id: id,
      userId: row['user_id']! as String,
      studentName: row['display_name']! as String,
      worldId: row['world_id']! as String,
      worldTitle: row['world_title']! as String,
      score: (row['score'] as int?) ?? 0,
      passed: row['passed'] == 1,
      status: AssessmentAttemptStatus.fromWireName(row['status']! as String),
      startedAt: startedAt,
      deadlineAt: row['deadline_at'] == null
          ? startedAt
          : DateTime.parse(row['deadline_at']! as String),
      submittedAt: submittedAt,
      durationSeconds: endAt.difference(startedAt).inSeconds,
      incidents: _incidentCount(id),
      reactivationCount: row['reactivation_count']! as int,
      topics: _topicScores(id),
    );
  }

  AssessmentAttempt _openAttempt(String userId, String attemptId) {
    final row = _openAttemptRow(userId, attemptId);
    if (row['status'] != 'open') {
      if (row['status'] == 'submitted') {
        throw const CatalogException(
          'attempt_submitted',
          'Este intento ya fue entregado.',
        );
      }
      throw const CatalogException(
        'attempt_annulled',
        'Este intento ya no está abierto.',
      );
    }
    final deadline = row['deadline_at'] as String?;
    return AssessmentAttempt(
      id: attemptId,
      worldId: row['world_id']! as String,
      worldTitle: row['world_title']! as String,
      startedAt: DateTime.parse(row['started_at']! as String),
      deadlineAt: DateTime.parse(deadline ?? row['started_at']! as String),
      settings: _settingsFor(row['world_id']! as String),
      draftAnswers: _draftAnswers(attemptId),
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

  Row _openAttemptRow(String userId, String attemptId) {
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
    return rows.single;
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

  Row? _activeSession(String worldId) {
    final rows = _database.select(
      '''
      SELECT * FROM assessment_sessions
      WHERE world_id = ? AND status = 'open'
      ORDER BY opened_at DESC
      LIMIT 1
    ''',
      [worldId],
    );
    return rows.isEmpty ? null : rows.single;
  }

  AssessmentWorldSettings _settingsFor(String worldId) {
    final rows = _database.select(
      'SELECT * FROM assessment_world_settings WHERE world_id = ?',
      [worldId],
    );
    if (rows.isEmpty) return AssessmentWorldSettings.defaults(worldId);
    final row = rows.single;
    return AssessmentWorldSettings(
      worldId: worldId,
      durationMinutes: row['duration_minutes']! as int,
      fullscreenRequired: row['fullscreen_required'] == 1,
      maxIncidents: row['max_incidents']! as int,
      returnGraceSeconds: row['return_grace_seconds']! as int,
      strictMode: row['strict_mode'] == 1,
    );
  }

  AssessmentSession _sessionById(String sessionId) {
    final rows = _database.select(
      '''
      SELECT s.*, w.title world_title
      FROM assessment_sessions s
      JOIN worlds w ON w.id = s.world_id
      WHERE s.id = ?
    ''',
      [sessionId],
    );
    if (rows.isEmpty) {
      throw const CatalogException(
        'session_not_found',
        'La sesión de parcial no existe.',
      );
    }
    return _sessionFromRow(rows.single);
  }

  AssessmentSession _sessionFromRow(Row row) {
    final worldId = row['world_id']! as String;
    final settings = AssessmentWorldSettings(
      worldId: worldId,
      durationMinutes: row['duration_minutes']! as int,
      fullscreenRequired: row['fullscreen_required'] == 1,
      maxIncidents: row['max_incidents']! as int,
      returnGraceSeconds: row['return_grace_seconds']! as int,
      strictMode: row['strict_mode'] == 1,
    );
    return AssessmentSession(
      id: row['id']! as String,
      worldId: worldId,
      worldTitle: row['world_title']! as String,
      status: AssessmentSessionStatus.fromWireName(row['status']! as String),
      openedAt: DateTime.parse(row['opened_at']! as String),
      closesAt: DateTime.parse(row['closes_at']! as String),
      closedAt: row['closed_at'] == null
          ? null
          : DateTime.parse(row['closed_at']! as String),
      durationMinutes: row['duration_minutes']! as int,
      settings: settings,
      attempts: _liveAttempts(row['id']! as String),
    );
  }

  List<AssessmentLiveAttempt> _liveAttempts(String sessionId) {
    return _database
        .select(
          '''
          SELECT aa.*, u.display_name
          FROM assessment_attempts aa
          JOIN users u ON u.id = aa.user_id
          WHERE aa.session_id = ?
          ORDER BY aa.started_at DESC
        ''',
          [sessionId],
        )
        .map(
          (row) => AssessmentLiveAttempt(
            attemptId: row['id']! as String,
            userId: row['user_id']! as String,
            studentName: row['display_name']! as String,
            status: AssessmentAttemptStatus.fromWireName(
              row['status']! as String,
            ),
            startedAt: DateTime.parse(row['started_at']! as String),
            deadlineAt: DateTime.parse(row['deadline_at']! as String),
            submittedAt: row['submitted_at'] == null
                ? null
                : DateTime.parse(row['submitted_at']! as String),
            score: row['score'] as int?,
            answeredQuestions: _answeredDraftCount(row['id']! as String),
            totalQuestions: row['total_questions']! as int,
            incidents: _incidentCount(row['id']! as String),
            reactivationCount: row['reactivation_count']! as int,
            annulledReason: row['annulled_reason'] as String?,
          ),
        )
        .toList();
  }

  Map<String, List<String>> _draftAnswers(String attemptId) {
    final rows = _database.select(
      '''
      SELECT question_id, option_id
      FROM assessment_draft_answers
      WHERE attempt_id = ?
      ORDER BY question_id, option_id
    ''',
      [attemptId],
    );
    final answers = <String, List<String>>{};
    for (final row in rows) {
      answers
          .putIfAbsent(row['question_id']! as String, () => <String>[])
          .add(row['option_id']! as String);
    }
    return answers;
  }

  int _answeredDraftCount(String attemptId) {
    return _database
            .select(
              '''
              SELECT COUNT(DISTINCT question_id) AS total
              FROM assessment_draft_answers
              WHERE attempt_id = ?
            ''',
              [attemptId],
            )
            .single['total']!
        as int;
  }

  int _incidentCount(String attemptId) {
    return _database
            .select(
              '''
              SELECT COUNT(*) AS total
              FROM assessment_attempt_events
              WHERE attempt_id = ?
                AND type IN ('fullscreen_exit', 'focus_lost', 'visibility_hidden', 'blocked_key', 'pagehide')
            ''',
              [attemptId],
            )
            .single['total']!
        as int;
  }

  void _annulAttempt(String attemptId, String reason, {required String type}) {
    final rows = _database.select(
      'SELECT session_id, user_id FROM assessment_attempts WHERE id = ?',
      [attemptId],
    );
    if (rows.isEmpty) return;
    _database.execute(
      '''
      UPDATE assessment_attempts
      SET status = 'annulled', annulled_at = ?, annulled_reason = ?
      WHERE id = ? AND status = 'open'
    ''',
      [_now(), reason, attemptId],
    );
    final sessionId = rows.single['session_id'] as String?;
    if (sessionId != null) {
      _recordEvent(
        sessionId,
        attemptId: attemptId,
        userId: rows.single['user_id'] as String?,
        type: type,
        message: reason,
      );
    }
  }

  AssessmentAttemptEvent _recordEvent(
    String sessionId, {
    String? attemptId,
    String? userId,
    required String type,
    required String message,
    int? answeredQuestions,
    int? totalQuestions,
    int? score,
  }) {
    final event = AssessmentAttemptEvent(
      id: _tokenService.newId(),
      sessionId: sessionId,
      attemptId: attemptId,
      userId: userId,
      studentName: userId == null ? null : _studentName(userId),
      type: type,
      message: message,
      occurredAt: _clock().toUtc(),
      answeredQuestions: answeredQuestions,
      totalQuestions: totalQuestions,
      score: score,
    );
    _database.execute(
      '''
      INSERT INTO assessment_attempt_events(
        id, session_id, attempt_id, user_id, type, message,
        answered_questions, total_questions, score, occurred_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''',
      [
        event.id,
        sessionId,
        attemptId,
        userId,
        type,
        message,
        answeredQuestions,
        totalQuestions,
        score,
        event.occurredAt.toIso8601String(),
      ],
    );
    _events.add(event);
    return event;
  }

  String? _studentName(String userId) {
    final rows = _database.select(
      'SELECT display_name FROM users WHERE id = ?',
      [userId],
    );
    return rows.isEmpty ? null : rows.single['display_name']! as String;
  }

  List<AssessmentAttemptEvent> _eventsForSession(String sessionId) {
    return _database
        .select(
          '''
          SELECT e.*, u.display_name
          FROM assessment_attempt_events e
          LEFT JOIN users u ON u.id = e.user_id
          WHERE e.session_id = ?
          ORDER BY e.occurred_at
        ''',
          [sessionId],
        )
        .map(_eventFromRow)
        .toList();
  }

  List<AssessmentAttemptEvent> _eventsForAttempt(String attemptId) {
    return _database
        .select(
          '''
          SELECT e.*, u.display_name
          FROM assessment_attempt_events e
          LEFT JOIN users u ON u.id = e.user_id
          WHERE e.attempt_id = ?
          ORDER BY e.occurred_at
        ''',
          [attemptId],
        )
        .map(_eventFromRow)
        .toList();
  }

  AssessmentAttemptEvent _eventFromRow(Row row) => AssessmentAttemptEvent(
    id: row['id']! as String,
    sessionId: row['session_id']! as String,
    attemptId: row['attempt_id'] as String?,
    userId: row['user_id'] as String?,
    studentName: row['display_name'] as String?,
    type: row['type']! as String,
    message: row['message']! as String,
    occurredAt: DateTime.parse(row['occurred_at']! as String),
    answeredQuestions: row['answered_questions'] as int?,
    totalQuestions: row['total_questions'] as int?,
    score: row['score'] as int?,
  );

  List<AssessmentQuestionReport> _questionReports(String attemptId) {
    return _database
        .select(
          '''
          SELECT * FROM assessment_attempt_questions
          WHERE attempt_id = ?
          ORDER BY position
        ''',
          [attemptId],
        )
        .map((question) {
          final questionId = question['question_id']! as String;
          final options = _optionRows(attemptId, questionId);
          final selected = _selected(attemptId, questionId).toSet();
          final correct = options
              .where((row) => row['is_correct'] == 1)
              .map((row) => row['option_id']! as String)
              .toSet();
          final isCorrect =
              selected.length == correct.length &&
              selected.containsAll(correct);
          return AssessmentQuestionReport(
            number: question['position']! as int,
            topicTitle: question['topic_title']! as String,
            prompt: question['prompt']! as String,
            selectedOptionTexts: options
                .where((row) => selected.contains(row['option_id']))
                .map((row) => row['text']! as String)
                .toList(),
            correctOptionTexts: options
                .where((row) => correct.contains(row['option_id']))
                .map((row) => row['text']! as String)
                .toList(),
            isCorrect: isCorrect,
            points: isCorrect ? 1 : 0,
            explanation: question['explanation']! as String,
          );
        })
        .toList();
  }

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

extension _SingleOrNull<T> on Iterable<T> {
  T? get singleOrNull => isEmpty ? null : single;
}
