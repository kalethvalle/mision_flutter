import 'package:sqlite3/sqlite3.dart';

import '../../application/analytics/analytics_service.dart';
import '../../core/models/analytics_model.dart';

class SqliteAnalyticsStore implements AnalyticsStore {
  SqliteAnalyticsStore(this._database);

  final Database _database;

  static const _incidentTypes = {
    'fullscreen_exit',
    'focus_lost',
    'blocked_key',
    'expired',
    'annulled',
  };

  @override
  Future<AnalyticsDashboard> dashboard() async {
    if (_database.select('SELECT id FROM dw_refresh_state LIMIT 1').isEmpty) {
      _rebuild();
    }
    return _dashboardFromWarehouse();
  }

  @override
  Future<AnalyticsDashboard> refresh() async {
    _rebuild();
    return _dashboardFromWarehouse();
  }

  void _rebuild() {
    _database.execute('BEGIN IMMEDIATE');
    try {
      for (final table in const [
        'dw_fact_integrity_event',
        'dw_fact_assessment_topic_score',
        'dw_fact_assessment_attempt',
        'dw_fact_training_attempt',
        'dw_dim_date',
        'dw_dim_mission',
        'dw_dim_topic',
        'dw_dim_world',
        'dw_dim_student',
      ]) {
        _database.execute('DELETE FROM $table');
      }

      _loadDimensions();
      _loadTrainingFacts();
      _loadAssessmentFacts();
      _loadIntegrityFacts();

      final now = DateTime.now().toUtc().toIso8601String();
      final auditCount = _scalarInt('SELECT COUNT(*) FROM analytics_audit_log');
      _database.execute(
        '''
        INSERT INTO dw_refresh_state(id, refreshed_at, source_event_count, note)
        VALUES ('main', ?, ?, 'full_rebuild')
        ON CONFLICT(id) DO UPDATE SET
          refreshed_at = excluded.refreshed_at,
          source_event_count = excluded.source_event_count,
          note = excluded.note
      ''',
        [now, auditCount],
      );
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  void _loadDimensions() {
    _database.execute('''
      INSERT INTO dw_dim_student(
        student_id, username, display_name, is_active, created_at
      )
      SELECT id, username, display_name, is_active, created_at
      FROM users
      WHERE role = 'student'
    ''');
    _database.execute('''
      INSERT INTO dw_dim_world(world_id, title, sort_order, status)
      SELECT id, title, sort_order, status
      FROM worlds
    ''');
    _database.execute('''
      INSERT INTO dw_dim_topic(topic_id, world_id, title, sort_order, status)
      SELECT id, world_id, title, sort_order, status
      FROM topics
    ''');
    _database.execute('''
      INSERT INTO dw_dim_mission(
        mission_id, world_id, topic_id, title, sort_order, status,
        content_version
      )
      SELECT id, world_id, topic_id, title, sort_order, status, content_version
      FROM missions
    ''');
  }

  void _loadTrainingFacts() {
    final rows = _database.select('''
      SELECT
        ta.id,
        ta.user_id,
        ta.mission_id,
        ta.is_correct,
        ta.hint_used,
        ta.attempted_at,
        m.world_id,
        m.topic_id
      FROM training_attempts ta
      JOIN users u ON u.id = ta.user_id AND u.role = 'student'
      JOIN missions m ON m.id = ta.mission_id
    ''');
    for (final row in rows) {
      final attemptedAt = DateTime.parse(row['attempted_at']! as String);
      final dateKey = _ensureDate(attemptedAt);
      _database.execute(
        '''
        INSERT INTO dw_fact_training_attempt(
          attempt_id, student_id, world_id, topic_id, mission_id, date_key,
          attempted_at, is_correct, hint_used
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          row['id'],
          row['user_id'],
          row['world_id'],
          row['topic_id'],
          row['mission_id'],
          dateKey,
          row['attempted_at'],
          row['is_correct'],
          row['hint_used'],
        ],
      );
    }
  }

  void _loadAssessmentFacts() {
    final rows = _database.select('''
      SELECT *
      FROM assessment_attempts
      WHERE status IN ('submitted', 'annulled')
    ''');
    for (final row in rows) {
      final attemptId = row['id']! as String;
      final finishedAtText =
          (row['submitted_at'] ?? row['annulled_at'] ?? row['started_at'])!
              as String;
      final dateKey = _ensureDate(DateTime.parse(finishedAtText));
      final incidents = _incidentCountForAttempt(attemptId);
      _database.execute(
        '''
        INSERT INTO dw_fact_assessment_attempt(
          attempt_id, student_id, world_id, date_key, started_at, finished_at,
          status, score, passed, correct_answers, total_questions, incidents,
          reactivation_count
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          attemptId,
          row['user_id'],
          row['world_id'],
          dateKey,
          row['started_at'],
          finishedAtText,
          row['status'],
          row['score'] ?? 0,
          row['passed'] ?? 0,
          row['correct_answers'] ?? 0,
          row['total_questions'],
          incidents,
          row['reactivation_count'] ?? 0,
        ],
      );
      _loadAssessmentTopicFacts(row, dateKey);
    }
  }

  void _loadAssessmentTopicFacts(Row attempt, int dateKey) {
    final attemptId = attempt['id']! as String;
    final questionRows = _database.select(
      '''
      SELECT question_id, topic_id
      FROM assessment_attempt_questions
      WHERE attempt_id = ?
    ''',
      [attemptId],
    );
    final topicTotals = <String, _TopicScore>{};
    for (final question in questionRows) {
      final questionId = question['question_id']! as String;
      final topicId = question['topic_id']! as String;
      final score = topicTotals.putIfAbsent(topicId, _TopicScore.new);
      score.total++;
      final selected = _database
          .select(
            '''
            SELECT option_id
            FROM assessment_answers
            WHERE attempt_id = ? AND question_id = ?
          ''',
            [attemptId, questionId],
          )
          .map((row) => row['option_id']! as String)
          .toSet();
      final expected = _database
          .select(
            '''
            SELECT option_id
            FROM assessment_attempt_options
            WHERE attempt_id = ? AND question_id = ? AND is_correct = 1
          ''',
            [attemptId, questionId],
          )
          .map((row) => row['option_id']! as String)
          .toSet();
      if (selected.length == expected.length &&
          selected.containsAll(expected)) {
        score.correct++;
      }
    }

    for (final entry in topicTotals.entries) {
      final score = entry.value;
      _database.execute(
        '''
        INSERT INTO dw_fact_assessment_topic_score(
          attempt_id, student_id, world_id, topic_id, date_key,
          correct_answers, total_questions, score
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          attemptId,
          attempt['user_id'],
          attempt['world_id'],
          entry.key,
          dateKey,
          score.correct,
          score.total,
          _percent(score.correct, score.total),
        ],
      );
    }
  }

  void _loadIntegrityFacts() {
    final rows = _database.select('''
      SELECT
        e.id,
        e.session_id,
        e.attempt_id,
        e.user_id,
        e.type,
        e.score,
        e.occurred_at,
        COALESCE(a.world_id, s.world_id) AS world_id
      FROM assessment_attempt_events e
      LEFT JOIN assessment_attempts a ON a.id = e.attempt_id
      LEFT JOIN assessment_sessions s ON s.id = e.session_id
    ''');
    for (final row in rows) {
      final occurredAt = DateTime.parse(row['occurred_at']! as String);
      final dateKey = _ensureDate(occurredAt);
      _database.execute(
        '''
        INSERT INTO dw_fact_integrity_event(
          event_id, student_id, world_id, attempt_id, session_id, date_key,
          type, score, occurred_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          row['id'],
          row['user_id'],
          row['world_id'],
          row['attempt_id'],
          row['session_id'],
          dateKey,
          row['type'],
          row['score'],
          row['occurred_at'],
        ],
      );
    }
  }

  AnalyticsDashboard _dashboardFromWarehouse() {
    final refreshedAt = _database.select(
      "SELECT refreshed_at FROM dw_refresh_state WHERE id = 'main'",
    );
    return AnalyticsDashboard(
      refreshedAt: refreshedAt.isEmpty
          ? null
          : DateTime.parse(refreshedAt.single['refreshed_at']! as String),
      summary: _summary(),
      studentEvolution: _studentEvolution(),
      academicPerformance: _academicPerformance(),
      topicDifficulty: _topicDifficulty(),
      integrity: _integrity(),
    );
  }

  AnalyticsKpiSummary _summary() {
    final trainingAttempts = _scalarInt(
      'SELECT COUNT(*) FROM dw_fact_training_attempt',
    );
    final correctTraining = _scalarInt(
      'SELECT COUNT(*) FROM dw_fact_training_attempt WHERE is_correct = 1',
    );
    final assessmentAttempts = _scalarInt(
      'SELECT COUNT(*) FROM dw_fact_assessment_attempt',
    );
    final approved = _scalarInt(
      'SELECT COUNT(*) FROM dw_fact_assessment_attempt WHERE passed = 1',
    );
    return AnalyticsKpiSummary(
      totalStudents: _scalarInt('SELECT COUNT(*) FROM dw_dim_student'),
      activeStudents: _activeStudentCount(),
      completedMissions: _scalarInt('''
        SELECT COUNT(*)
        FROM (
          SELECT DISTINCT student_id, mission_id
          FROM dw_fact_training_attempt
          WHERE is_correct = 1
        )
      '''),
      trainingAttempts: trainingAttempts,
      trainingAccuracy: _percent(correctTraining, trainingAttempts),
      averageAssessmentScore: _scalarInt(
        'SELECT ROUND(COALESCE(AVG(score), 0)) FROM dw_fact_assessment_attempt',
      ),
      approvalRate: _percent(approved, assessmentAttempts),
      incidents: _incidentCount(),
      annulledAttempts: _scalarInt(
        "SELECT COUNT(*) FROM dw_fact_assessment_attempt WHERE status = 'annulled'",
      ),
    );
  }

  List<StudentEvolutionMetric> _studentEvolution() {
    final totalMissions = _scalarInt(
      "SELECT COUNT(*) FROM dw_dim_mission WHERE status = 'published'",
    );
    final rows = _database.select('''
      SELECT
        s.student_id,
        s.display_name,
        MIN(activity.first_at) AS first_activity_at,
        COALESCE(days.active_days, 0) AS active_days,
        COALESCE(done.completed_missions, 0) AS completed_missions,
        COALESCE(train.correct_count, 0) AS correct_count,
        COALESCE(train.total_count, 0) AS training_count,
        COALESCE(MAX(a.score), 0) AS best_score
      FROM dw_dim_student s
      LEFT JOIN (
        SELECT student_id, MIN(attempted_at) AS first_at
        FROM dw_fact_training_attempt
        GROUP BY student_id
        UNION ALL
        SELECT student_id, MIN(started_at) AS first_at
        FROM dw_fact_assessment_attempt
        GROUP BY student_id
      ) activity ON activity.student_id = s.student_id
      LEFT JOIN (
        SELECT student_id, COUNT(DISTINCT date_key) AS active_days
        FROM (
          SELECT student_id, date_key FROM dw_fact_training_attempt
          UNION
          SELECT student_id, date_key FROM dw_fact_assessment_attempt
        )
        GROUP BY student_id
      ) days ON days.student_id = s.student_id
      LEFT JOIN (
        SELECT student_id, COUNT(DISTINCT mission_id) AS completed_missions
        FROM dw_fact_training_attempt
        WHERE is_correct = 1
        GROUP BY student_id
      ) done ON done.student_id = s.student_id
      LEFT JOIN (
        SELECT
          student_id,
          SUM(is_correct) AS correct_count,
          COUNT(*) AS total_count
        FROM dw_fact_training_attempt
        GROUP BY student_id
      ) train ON train.student_id = s.student_id
      LEFT JOIN dw_fact_assessment_attempt a ON a.student_id = s.student_id
      GROUP BY s.student_id, s.display_name
      ORDER BY active_days DESC, s.display_name
      LIMIT 50
    ''');
    return rows.map((row) {
      final studentId = row['student_id']! as String;
      final latest = _latestAssessmentScore(studentId);
      return StudentEvolutionMetric(
        studentId: studentId,
        studentName: row['display_name']! as String,
        firstActivityAt: row['first_activity_at'] == null
            ? null
            : DateTime.parse(row['first_activity_at']! as String),
        activeDays: _rowInt(row, 'active_days'),
        completedMissions: _rowInt(row, 'completed_missions'),
        totalMissions: totalMissions,
        trainingAccuracy: _percent(
          _rowInt(row, 'correct_count'),
          _rowInt(row, 'training_count'),
        ),
        recentTrainingAccuracy: _recentTrainingAccuracy(studentId),
        bestAssessmentScore: _rowInt(row, 'best_score'),
        latestAssessmentScore: latest,
      );
    }).toList();
  }

  List<AcademicPerformanceMetric> _academicPerformance() {
    final rows = _database.select('''
      SELECT
        s.student_id,
        s.display_name,
        ROUND(COALESCE(AVG(a.score), 0)) AS average_score,
        COALESCE(SUM(a.passed), 0) AS approved_attempts,
        COUNT(a.attempt_id) AS total_attempts,
        COALESCE(train.correct_count, 0) AS correct_count,
        COALESCE(train.total_count, 0) AS training_count
      FROM dw_dim_student s
      LEFT JOIN dw_fact_assessment_attempt a ON a.student_id = s.student_id
      LEFT JOIN (
        SELECT
          student_id,
          SUM(is_correct) AS correct_count,
          COUNT(*) AS total_count
        FROM dw_fact_training_attempt
        GROUP BY student_id
      ) train ON train.student_id = s.student_id
      GROUP BY s.student_id, s.display_name
      ORDER BY average_score DESC, training_count DESC, s.display_name
      LIMIT 50
    ''');
    return rows.map((row) {
      final trainingAccuracy = _percent(
        _rowInt(row, 'correct_count'),
        _rowInt(row, 'training_count'),
      );
      final averageScore = _rowInt(row, 'average_score');
      return AcademicPerformanceMetric(
        studentId: row['student_id']! as String,
        studentName: row['display_name']! as String,
        averageScore: averageScore,
        approvedAttempts: _rowInt(row, 'approved_attempts'),
        totalAttempts: _rowInt(row, 'total_attempts'),
        trainingAccuracy: trainingAccuracy,
        trainingAssessmentGap: trainingAccuracy - averageScore,
      );
    }).toList();
  }

  List<TopicDifficultyMetric> _topicDifficulty() {
    final rows = _database.select('''
      SELECT
        t.topic_id,
        t.title AS topic_title,
        w.title AS world_title,
        COALESCE(train.correct_count, 0) AS train_correct,
        COALESCE(train.total_count, 0) AS train_total,
        ROUND(COALESCE(AVG(score.score), 0)) AS assessment_score,
        COALESCE(train.total_count, 0) + COUNT(score.attempt_id) AS attempts
      FROM dw_dim_topic t
      JOIN dw_dim_world w ON w.world_id = t.world_id
      LEFT JOIN (
        SELECT
          topic_id,
          SUM(is_correct) AS correct_count,
          COUNT(*) AS total_count
        FROM dw_fact_training_attempt
        GROUP BY topic_id
      ) train ON train.topic_id = t.topic_id
      LEFT JOIN dw_fact_assessment_topic_score score
        ON score.topic_id = t.topic_id
      WHERE t.status = 'published'
      GROUP BY t.topic_id, t.title, w.title
      ORDER BY ((COALESCE(train.correct_count, 0) * 100.0 /
        CASE WHEN COALESCE(train.total_count, 0) = 0 THEN 1 ELSE train.total_count END)
        + COALESCE(AVG(score.score), 0)) ASC, attempts DESC
      LIMIT 30
    ''');
    return rows.map((row) {
      return TopicDifficultyMetric(
        topicId: row['topic_id']! as String,
        topicTitle: row['topic_title']! as String,
        worldTitle: row['world_title']! as String,
        trainingAccuracy: _percent(
          _rowInt(row, 'train_correct'),
          _rowInt(row, 'train_total'),
        ),
        assessmentScore: _rowInt(row, 'assessment_score'),
        attempts: _rowInt(row, 'attempts'),
      );
    }).toList();
  }

  List<IntegrityMetric> _integrity() {
    final rows = _database.select('''
      SELECT
        s.student_id,
        s.display_name,
        COALESCE(i.incidents, 0) AS incidents,
        COALESCE(a.annulled_attempts, 0) AS annulled_attempts,
        COALESCE(a.reactivations, 0) AS reactivations
      FROM dw_dim_student s
      LEFT JOIN (
        SELECT student_id, COUNT(*) AS incidents
        FROM dw_fact_integrity_event
        WHERE type IN (${_incidentPlaceholders()})
        GROUP BY student_id
      ) i ON i.student_id = s.student_id
      LEFT JOIN (
        SELECT
          student_id,
          SUM(CASE WHEN status = 'annulled' THEN 1 ELSE 0 END)
            AS annulled_attempts,
          SUM(reactivation_count) AS reactivations
        FROM dw_fact_assessment_attempt
        GROUP BY student_id
      ) a ON a.student_id = s.student_id
      WHERE COALESCE(i.incidents, 0) > 0
        OR COALESCE(a.annulled_attempts, 0) > 0
        OR COALESCE(a.reactivations, 0) > 0
      ORDER BY incidents DESC, annulled_attempts DESC, s.display_name
      LIMIT 50
    ''', _incidentTypes.toList());
    return rows.map((row) {
      final incidents = _rowInt(row, 'incidents');
      final annulled = _rowInt(row, 'annulled_attempts');
      final reactivations = _rowInt(row, 'reactivations');
      return IntegrityMetric(
        studentId: row['student_id']! as String,
        studentName: row['display_name']! as String,
        incidents: incidents,
        annulledAttempts: annulled,
        reactivations: reactivations,
        riskLevel: _riskLevel(incidents, annulled, reactivations),
      );
    }).toList();
  }

  int _ensureDate(DateTime value) {
    final utc = value.toUtc();
    final key = utc.year * 10000 + utc.month * 100 + utc.day;
    final week = ((utc.day - 1) ~/ 7) + 1;
    _database.execute(
      '''
      INSERT OR IGNORE INTO dw_dim_date(
        date_key, date_text, year, month, day, week_label
      ) VALUES (?, ?, ?, ?, ?, ?)
    ''',
      [
        key,
        '${utc.year.toString().padLeft(4, '0')}-'
            '${utc.month.toString().padLeft(2, '0')}-'
            '${utc.day.toString().padLeft(2, '0')}',
        utc.year,
        utc.month,
        utc.day,
        '${utc.year}-M${utc.month.toString().padLeft(2, '0')}-S$week',
      ],
    );
    return key;
  }

  int _activeStudentCount() {
    return _scalarInt('''
      SELECT COUNT(*)
      FROM (
        SELECT student_id FROM dw_fact_training_attempt
        UNION
        SELECT student_id FROM dw_fact_assessment_attempt
      )
    ''');
  }

  int _incidentCount() {
    return _scalarInt('''
      SELECT COUNT(*)
      FROM dw_fact_integrity_event
      WHERE type IN (${_incidentPlaceholders()})
    ''', _incidentTypes.toList());
  }

  int _incidentCountForAttempt(String attemptId) {
    return _scalarInt(
      '''
      SELECT COUNT(*)
      FROM assessment_attempt_events
      WHERE attempt_id = ?
        AND type IN (${_incidentPlaceholders()})
    ''',
      [attemptId, ..._incidentTypes],
    );
  }

  int _latestAssessmentScore(String studentId) {
    final rows = _database.select(
      '''
      SELECT score
      FROM dw_fact_assessment_attempt
      WHERE student_id = ?
      ORDER BY finished_at DESC
      LIMIT 1
    ''',
      [studentId],
    );
    return rows.isEmpty ? 0 : rows.single['score']! as int;
  }

  int _recentTrainingAccuracy(String studentId) {
    final rows = _database.select(
      '''
      SELECT is_correct
      FROM dw_fact_training_attempt
      WHERE student_id = ?
      ORDER BY attempted_at DESC
      LIMIT 5
    ''',
      [studentId],
    );
    if (rows.isEmpty) return 0;
    final correct = rows.where((row) => row['is_correct'] == 1).length;
    return _percent(correct, rows.length);
  }

  int _scalarInt(String sql, [List<Object?> parameters = const []]) {
    final rows = _database.select(sql, parameters);
    if (rows.isEmpty) return 0;
    final value = rows.single.values.first;
    if (value is int) return value;
    if (value is double) return value.round();
    return 0;
  }

  int _rowInt(Row row, String key) {
    final value = row[key];
    if (value is int) return value;
    if (value is double) return value.round();
    return 0;
  }

  String _incidentPlaceholders() {
    return List.filled(_incidentTypes.length, '?').join(', ');
  }

  int _percent(int numerator, int denominator) {
    if (denominator <= 0) return 0;
    return (100 * numerator / denominator).round();
  }

  String _riskLevel(int incidents, int annulled, int reactivations) {
    if (annulled > 0 || incidents >= 5) return 'alto';
    if (incidents >= 2 || reactivations > 0) return 'medio';
    return 'bajo';
  }
}

class _TopicScore {
  int correct = 0;
  int total = 0;
}
