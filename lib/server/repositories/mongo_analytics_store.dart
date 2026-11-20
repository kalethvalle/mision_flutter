import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:sqlite3/sqlite3.dart';

import '../../application/analytics/analytics_service.dart';
import '../../core/models/analytics_model.dart';
import 'sqlite_analytics_store.dart';

class MongoAnalyticsStore implements AnalyticsStore {
  MongoAnalyticsStore({
    required Database sqliteDatabase,
    required this.mongoUri,
    required this.mongoDatabase,
  }) : _database = sqliteDatabase,
       _sqliteStore = SqliteAnalyticsStore(sqliteDatabase);

  final Database _database;
  final String mongoUri;
  final String mongoDatabase;
  final SqliteAnalyticsStore _sqliteStore;

  mongo.Db? _mongo;

  @override
  Future<AnalyticsDashboard> dashboard() async {
    final db = await _openMongo();
    final snapshot = await db.collection('teacher_metric_snapshots').findOne({
      '_id': 'current',
    });
    if (snapshot == null) {
      return refresh();
    }
    final dashboard = snapshot['dashboard'];
    if (dashboard is! Map) {
      return refresh();
    }
    return AnalyticsDashboard.fromJson(_asObjectMap(dashboard));
  }

  @override
  Future<AnalyticsDashboard> refresh() async {
    final dashboard = await _sqliteStore.refresh();
    final refreshedAt = DateTime.now().toUtc();
    final runId = 'analytics_${refreshedAt.microsecondsSinceEpoch}';
    final export = _MongoAnalyticsExport.fromSqlite(
      database: _database,
      dashboard: dashboard,
      runId: runId,
      refreshedAt: refreshedAt,
    );
    final db = await _openMongo();
    try {
      await _replaceCollection(db.collection('students'), export.students);
      await _replaceCollection(
        db.collection('learning_catalog'),
        export.learningCatalog,
      );
      await _replaceCollection(
        db.collection('training_attempts'),
        export.trainingAttempts,
      );
      await _replaceCollection(
        db.collection('assessment_attempts'),
        export.assessmentAttempts,
      );
      await _replaceCollection(
        db.collection('integrity_events'),
        export.integrityEvents,
      );

      final snapshot = export.snapshot;
      await db.collection('teacher_metric_snapshots').insertOne(snapshot);
      await _publishCurrentSnapshot(
        db.collection('teacher_metric_snapshots'),
        export.currentSnapshot,
      );
      await db.collection('etl_runs').insertOne(export.successRun);
      return dashboard;
    } on Object catch (error) {
      await _recordFailedRun(db, runId, refreshedAt, error);
      rethrow;
    }
  }

  Future<void> close() async {
    final db = _mongo;
    _mongo = null;
    await db?.close();
  }

  Future<mongo.Db> _openMongo() async {
    final current = _mongo;
    if (current != null && current.isConnected) return current;
    final db = await mongo.Db.create(mongoUri);
    await db.open();
    _mongo = db;
    return db;
  }

  Future<void> _replaceCollection(
    mongo.DbCollection collection,
    List<Map<String, Object?>> documents,
  ) async {
    await collection.deleteMany({});
    if (documents.isNotEmpty) {
      await collection.insertMany(documents);
    }
  }

  Future<void> _publishCurrentSnapshot(
    mongo.DbCollection snapshots,
    Map<String, Object?> document,
  ) async {
    final existing = await snapshots.findOne({'_id': 'current'});
    if (existing == null) {
      await snapshots.insertOne(document);
      return;
    }
    await snapshots.replaceOne({'_id': 'current'}, document);
  }

  Future<void> _recordFailedRun(
    mongo.Db db,
    String runId,
    DateTime startedAt,
    Object error,
  ) async {
    try {
      await db.collection('etl_runs').insertOne({
        '_id': '${runId}_failed',
        'runId': runId,
        'source': 'sqlite',
        'target': mongoDatabase,
        'status': 'failed',
        'startedAt': startedAt,
        'finishedAt': DateTime.now().toUtc(),
        'error': error.toString(),
      });
    } on Object {
      // El error original del refresh es mas util para el caller.
    }
  }

  Map<String, Object?> _asObjectMap(Map value) {
    return value.map((key, item) => MapEntry(key.toString(), _normalize(item)));
  }

  Object? _normalize(Object? value) {
    if (value is Map) return _asObjectMap(value);
    if (value is List) return value.map(_normalize).toList();
    return value;
  }
}

class _MongoAnalyticsExport {
  const _MongoAnalyticsExport({
    required this.students,
    required this.learningCatalog,
    required this.trainingAttempts,
    required this.assessmentAttempts,
    required this.integrityEvents,
    required this.snapshot,
    required this.currentSnapshot,
    required this.successRun,
  });

  final List<Map<String, Object?>> students;
  final List<Map<String, Object?>> learningCatalog;
  final List<Map<String, Object?>> trainingAttempts;
  final List<Map<String, Object?>> assessmentAttempts;
  final List<Map<String, Object?>> integrityEvents;
  final Map<String, Object?> snapshot;
  final Map<String, Object?> currentSnapshot;
  final Map<String, Object?> successRun;

  static _MongoAnalyticsExport fromSqlite({
    required Database database,
    required AnalyticsDashboard dashboard,
    required String runId,
    required DateTime refreshedAt,
  }) {
    final students = _students(database, runId);
    final learningCatalog = _learningCatalog(database, runId);
    final trainingAttempts = _trainingAttempts(database, runId);
    final assessmentAttempts = _assessmentAttempts(database, runId);
    final integrityEvents = _integrityEvents(database, runId);
    final dashboardJson = dashboard.toJson();
    final snapshot = {
      '_id': runId,
      'runId': runId,
      'refreshedAt': refreshedAt,
      'dashboard': dashboardJson,
      ...dashboardJson,
    };
    final currentSnapshot = {
      ...snapshot,
      '_id': 'current',
      'snapshotId': runId,
    };
    final successRun = {
      '_id': runId,
      'runId': runId,
      'source': 'sqlite',
      'status': 'success',
      'startedAt': refreshedAt,
      'finishedAt': DateTime.now().toUtc(),
      'counts': {
        'students': students.length,
        'learningCatalog': learningCatalog.length,
        'trainingAttempts': trainingAttempts.length,
        'assessmentAttempts': assessmentAttempts.length,
        'integrityEvents': integrityEvents.length,
      },
    };
    return _MongoAnalyticsExport(
      students: students,
      learningCatalog: learningCatalog,
      trainingAttempts: trainingAttempts,
      assessmentAttempts: assessmentAttempts,
      integrityEvents: integrityEvents,
      snapshot: snapshot,
      currentSnapshot: currentSnapshot,
      successRun: successRun,
    );
  }

  static List<Map<String, Object?>> _students(Database database, String runId) {
    return database
        .select('''
          SELECT id, username, display_name, role, is_active, created_at
          FROM users
          WHERE role = 'student'
          ORDER BY display_name
        ''')
        .map(
          (row) => {
            '_id': row['id'],
            'runId': runId,
            'username': row['username'],
            'displayName': row['display_name'],
            'role': row['role'],
            'isActive': row['is_active'] == 1,
            'createdAt': _date(row['created_at']),
          },
        )
        .toList();
  }

  static List<Map<String, Object?>> _learningCatalog(
    Database database,
    String runId,
  ) {
    return database
        .select('''
          SELECT id, title, status, sort_order
          FROM worlds
          ORDER BY sort_order
        ''')
        .map((world) {
          final worldId = world['id']! as String;
          return {
            '_id': worldId,
            'runId': runId,
            'title': world['title'],
            'status': world['status'],
            'sortOrder': world['sort_order'],
            'topics': database
                .select(
                  '''
                    SELECT id, title, status, sort_order
                    FROM topics
                    WHERE world_id = ?
                    ORDER BY sort_order
                  ''',
                  [worldId],
                )
                .map(
                  (topic) => {
                    'id': topic['id'],
                    'title': topic['title'],
                    'status': topic['status'],
                    'sortOrder': topic['sort_order'],
                  },
                )
                .toList(),
            'missions': database
                .select(
                  '''
                    SELECT id, topic_id, title, status, sort_order,
                      selection_type, content_version
                    FROM missions
                    WHERE world_id = ?
                    ORDER BY sort_order
                  ''',
                  [worldId],
                )
                .map(
                  (mission) => {
                    'id': mission['id'],
                    'topicId': mission['topic_id'],
                    'title': mission['title'],
                    'status': mission['status'],
                    'sortOrder': mission['sort_order'],
                    'selectionType': mission['selection_type'],
                    'contentVersion': mission['content_version'],
                  },
                )
                .toList(),
          };
        })
        .toList();
  }

  static List<Map<String, Object?>> _trainingAttempts(
    Database database,
    String runId,
  ) {
    return database
        .select('''
          SELECT
            ta.id,
            ta.user_id,
            u.display_name,
            ta.mission_id,
            m.world_id,
            m.topic_id,
            ta.selected_option_id,
            ta.is_correct,
            ta.hint_used,
            ta.attempted_at,
            ta.content_version
          FROM training_attempts ta
          JOIN users u ON u.id = ta.user_id AND u.role = 'student'
          JOIN missions m ON m.id = ta.mission_id
          ORDER BY ta.attempted_at
        ''')
        .map((row) {
          final attemptId = row['id']! as String;
          final selected = database
              .select(
                '''
                  SELECT option_id
                  FROM training_attempt_options
                  WHERE attempt_id = ?
                  ORDER BY option_id
                ''',
                [attemptId],
              )
              .map((option) => option['option_id']! as String)
              .toList();
          return {
            '_id': attemptId,
            'runId': runId,
            'studentId': row['user_id'],
            'studentName': row['display_name'],
            'worldId': row['world_id'],
            'topicId': row['topic_id'],
            'missionId': row['mission_id'],
            'selectedOptionIds': selected.isEmpty
                ? [row['selected_option_id']]
                : selected,
            'isCorrect': row['is_correct'] == 1,
            'hintUsed': row['hint_used'] == 1,
            'contentVersion': row['content_version'],
            'attemptedAt': _date(row['attempted_at']),
            'dateKey': _dateKey(row['attempted_at']),
          };
        })
        .toList();
  }

  static List<Map<String, Object?>> _assessmentAttempts(
    Database database,
    String runId,
  ) {
    return database
        .select('''
          SELECT
            a.*,
            u.display_name AS student_name,
            w.title AS world_title
          FROM assessment_attempts a
          JOIN users u ON u.id = a.user_id AND u.role = 'student'
          JOIN worlds w ON w.id = a.world_id
          WHERE a.status IN ('submitted', 'annulled')
          ORDER BY COALESCE(a.submitted_at, a.annulled_at, a.started_at)
        ''')
        .map((row) {
          final attemptId = row['id']! as String;
          return {
            '_id': attemptId,
            'runId': runId,
            'studentId': row['user_id'],
            'studentName': row['student_name'],
            'worldId': row['world_id'],
            'worldTitle': row['world_title'],
            'sessionId': row['session_id'],
            'status': row['status'],
            'score': row['score'] ?? 0,
            'passed': row['passed'] == 1,
            'correctAnswers': row['correct_answers'] ?? 0,
            'totalQuestions': row['total_questions'],
            'reactivationCount': row['reactivation_count'] ?? 0,
            'startedAt': _date(row['started_at']),
            'finishedAt': _date(
              row['submitted_at'] ?? row['annulled_at'] ?? row['started_at'],
            ),
            'topicScores': _topicScores(database, attemptId),
            'questionReview': _questionReview(database, attemptId),
          };
        })
        .toList();
  }

  static List<Map<String, Object?>> _topicScores(
    Database database,
    String attemptId,
  ) {
    return database
        .select(
          '''
            SELECT topic_id, correct_answers, total_questions, score
            FROM dw_fact_assessment_topic_score
            WHERE attempt_id = ?
            ORDER BY topic_id
          ''',
          [attemptId],
        )
        .map(
          (row) => {
            'topicId': row['topic_id'],
            'correctAnswers': row['correct_answers'],
            'totalQuestions': row['total_questions'],
            'score': row['score'],
          },
        )
        .toList();
  }

  static List<Map<String, Object?>> _questionReview(
    Database database,
    String attemptId,
  ) {
    return database
        .select(
          '''
            SELECT question_id, position, topic_id, topic_title,
              question_type, prompt, explanation
            FROM assessment_attempt_questions
            WHERE attempt_id = ?
            ORDER BY position
          ''',
          [attemptId],
        )
        .map((question) {
          final questionId = question['question_id']! as String;
          return {
            'questionId': questionId,
            'position': question['position'],
            'topicId': question['topic_id'],
            'topicTitle': question['topic_title'],
            'questionType': question['question_type'],
            'prompt': question['prompt'],
            'explanation': question['explanation'],
            'selectedOptionIds': _options(
              database,
              attemptId,
              questionId,
              onlySelected: true,
            ),
            'correctOptionIds': _options(
              database,
              attemptId,
              questionId,
              onlyCorrect: true,
            ),
          };
        })
        .toList();
  }

  static List<String> _options(
    Database database,
    String attemptId,
    String questionId, {
    bool onlySelected = false,
    bool onlyCorrect = false,
  }) {
    final sql = onlySelected
        ? '''
            SELECT option_id
            FROM assessment_answers
            WHERE attempt_id = ? AND question_id = ?
            ORDER BY option_id
          '''
        : '''
            SELECT option_id
            FROM assessment_attempt_options
            WHERE attempt_id = ? AND question_id = ? AND is_correct = ?
            ORDER BY option_id
          ''';
    final params = onlySelected
        ? <Object?>[attemptId, questionId]
        : <Object?>[attemptId, questionId, onlyCorrect ? 1 : 0];
    return database
        .select(sql, params)
        .map((row) => row['option_id']! as String)
        .toList();
  }

  static List<Map<String, Object?>> _integrityEvents(
    Database database,
    String runId,
  ) {
    return database
        .select('''
          SELECT
            e.id,
            e.session_id,
            e.attempt_id,
            e.user_id,
            u.display_name AS student_name,
            COALESCE(a.world_id, s.world_id) AS world_id,
            e.type,
            e.message,
            e.score,
            e.occurred_at
          FROM assessment_attempt_events e
          LEFT JOIN users u ON u.id = e.user_id
          LEFT JOIN assessment_attempts a ON a.id = e.attempt_id
          LEFT JOIN assessment_sessions s ON s.id = e.session_id
          ORDER BY e.occurred_at
        ''')
        .map(
          (row) => {
            '_id': row['id'],
            'runId': runId,
            'studentId': row['user_id'],
            'studentName': row['student_name'],
            'worldId': row['world_id'],
            'attemptId': row['attempt_id'],
            'sessionId': row['session_id'],
            'type': row['type'],
            'message': row['message'],
            'score': row['score'],
            'occurredAt': _date(row['occurred_at']),
            'dateKey': _dateKey(row['occurred_at']),
          },
        )
        .toList();
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    return DateTime.parse(value as String).toUtc();
  }

  static int? _dateKey(Object? value) {
    final date = _date(value);
    if (date == null) return null;
    return date.year * 10000 + date.month * 100 + date.day;
  }
}
