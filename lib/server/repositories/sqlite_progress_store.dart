import 'package:sqlite3/sqlite3.dart';

import '../../application/progress/progress_service.dart';
import '../../core/models/answer_check_result.dart';
import '../../core/models/progress_model.dart';
import '../../core/repositories/catalog_repository.dart';
import '../security/security_service.dart';

class SqliteProgressStore implements ProgressStore, TrainingStore {
  SqliteProgressStore(
    this._database, {
    SecureTokenService? tokenService,
    DateTime Function()? clock,
  }) : _tokenService = tokenService ?? SecureTokenService(),
       _clock = clock ?? DateTime.now;

  final Database _database;
  final SecureTokenService _tokenService;
  final DateTime Function() _clock;

  @override
  Future<StudentProgress> loadProgress(String userId) async {
    return _loadProgress(userId);
  }

  StudentProgress _loadProgress(String userId) {
    final completedMissionIds = _database
        .select('SELECT mission_id FROM mission_progress WHERE user_id = ?', [
          userId,
        ])
        .map((row) => row['mission_id']! as String)
        .toSet();
    final worldRows = _database.select('''
      SELECT id, title
      FROM worlds
      WHERE status = 'published'
      ORDER BY sort_order
    ''');

    final worlds = <WorldProgressState>[];
    final missions = <MissionProgressState>[];
    var previousWorldComplete = true;
    String? previousWorldTitle;

    for (var worldIndex = 0; worldIndex < worldRows.length; worldIndex++) {
      final worldId = worldRows[worldIndex]['id']! as String;
      final missionRows = _database.select(
        '''
        SELECT m.id
        FROM missions m
        JOIN topics t ON t.id = m.topic_id
        WHERE m.world_id = ?
          AND m.status = 'published'
          AND t.status = 'published'
        ORDER BY m.sort_order
      ''',
        [worldId],
      );
      final worldUnlocked = worldIndex == 0 || previousWorldComplete;
      var previousMissionComplete = true;
      var completedCount = 0;

      for (
        var missionIndex = 0;
        missionIndex < missionRows.length;
        missionIndex++
      ) {
        final missionId = missionRows[missionIndex]['id']! as String;
        final completed = completedMissionIds.contains(missionId);
        if (completed) completedCount++;
        final sequentiallyUnlocked =
            worldUnlocked && (missionIndex == 0 || previousMissionComplete);
        missions.add(
          MissionProgressState(
            missionId: missionId,
            worldId: worldId,
            isCompleted: completed,
            isUnlocked: completed || sequentiallyUnlocked,
          ),
        );
        previousMissionComplete = completed;
      }

      worlds.add(
        WorldProgressState(
          worldId: worldId,
          completedMissions: completedCount,
          totalMissions: missionRows.length,
          isUnlocked: worldUnlocked,
          lockReason: worldUnlocked
              ? null
              : 'Completa todas las misiones de ${previousWorldTitle ?? 'el mundo anterior'}.',
        ),
      );
      previousWorldComplete =
          missionRows.isNotEmpty && completedCount == missionRows.length;
      previousWorldTitle = worldRows[worldIndex]['title']! as String;
    }
    return StudentProgress(worlds: worlds, missions: missions);
  }

  @override
  Future<AnswerCheckResult> checkAndRecord({
    required String userId,
    required String missionId,
    required List<String> optionIds,
    required bool hintUsed,
  }) async {
    late bool correct;
    _database.execute('BEGIN IMMEDIATE');
    try {
      final missionProgress = _loadProgress(userId).mission(missionId);
      if (missionProgress == null) {
        throw const CatalogException(
          'mission_not_found',
          'La misión no existe o no está publicada.',
        );
      }
      if (!missionProgress.isUnlocked) {
        throw const CatalogException(
          'mission_locked',
          'Completa la misión anterior antes de continuar.',
        );
      }

      final selected = optionIds.toSet();
      final optionRows = _database.select(
        '''
        SELECT mo.id, mo.is_correct, m.content_version, m.selection_type
        FROM mission_options mo
        JOIN missions m ON m.id = mo.mission_id
        WHERE mo.mission_id = ?
          AND m.status = 'published'
          AND mo.is_active = 1
      ''',
        [missionId],
      );
      if (optionRows.isEmpty ||
          !selected.every(
            (optionId) => optionRows.any((row) => row['id'] == optionId),
          )) {
        throw const CatalogException(
          'invalid_option',
          'La opción no pertenece a la misión indicada.',
        );
      }

      final firstRow = optionRows.first;
      final selectionType = firstRow['selection_type']! as String;
      if (selectionType == 'single' && selected.length != 1) {
        throw const CatalogException(
          'invalid_option',
          'Esta misión requiere seleccionar una sola opción.',
        );
      }
      final correctOptions = optionRows
          .where((row) => row['is_correct'] == 1)
          .map((row) => row['id']! as String)
          .toSet();
      correct =
          selected.length == correctOptions.length &&
          selected.every(correctOptions.contains);
      final attemptedAt = _clock().toUtc().toIso8601String();
      final attemptId = _tokenService.newId();
      final legacySelectedOptionId = selected.first;
      _database.execute(
        '''
        INSERT INTO training_attempts(
          id, user_id, mission_id, selected_option_id, is_correct,
          hint_used, attempted_at, content_version
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ''',
        [
          attemptId,
          userId,
          missionId,
          legacySelectedOptionId,
          correct ? 1 : 0,
          hintUsed ? 1 : 0,
          attemptedAt,
          firstRow['content_version']! as int,
        ],
      );
      for (final optionId in selected) {
        _database.execute(
          '''
          INSERT INTO training_attempt_options(attempt_id, mission_id, option_id)
          VALUES (?, ?, ?)
        ''',
          [attemptId, missionId, optionId],
        );
      }

      if (correct) {
        _database.execute(
          '''
          INSERT INTO mission_progress(
            user_id, mission_id, completed_at, last_attempt_at
          ) VALUES (?, ?, ?, ?)
          ON CONFLICT(user_id, mission_id) DO UPDATE SET
            last_attempt_at = excluded.last_attempt_at
        ''',
          [userId, missionId, attemptedAt, attemptedAt],
        );
      }
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }

    final progress = _loadProgress(userId);
    return AnswerCheckResult(
      missionId: missionId,
      isCorrect: correct,
      message: correct
          ? '¡Excelente! Misión completada.'
          : 'La respuesta no es correcta. Intenta con otra opción.',
      progress: progress,
    );
  }
}
