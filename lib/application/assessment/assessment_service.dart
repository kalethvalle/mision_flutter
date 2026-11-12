import '../../core/models/assessment_model.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/catalog_repository.dart';

abstract interface class AssessmentStore {
  Future<AssessmentOverview> overview(String userId);

  Future<AssessmentAttempt> start(String userId, String worldId);

  Future<AssessmentAttempt> loadAttempt(String userId, String attemptId);

  Future<AssessmentResult> submit(
    String userId,
    String attemptId,
    Map<String, List<String>> answers,
  );

  Future<void> saveDraftAnswers(
    String userId,
    String attemptId,
    Map<String, List<String>> answers,
  );

  Future<AssessmentAttempt> recordIncident(
    String userId,
    String attemptId, {
    required String type,
    required String message,
  });

  Future<AssessmentResult> loadResult(String userId, String attemptId);

  Future<TeacherReport> report({
    String? studentId,
    String? worldId,
    String? topicId,
  });

  Future<AssessmentSessionOverview> sessionOverview();

  Future<AssessmentWorldSettings> saveSettings(
    AssessmentWorldSettings settings,
  );

  Future<AssessmentSession> openSession(String teacherId, String worldId);

  Future<AssessmentSession> closeSession(String teacherId, String sessionId);

  Future<AssessmentSession> reactivateAttempt(
    String teacherId,
    String attemptId, {
    required String reason,
  });

  Future<AssessmentDetailReport> detailReport(String attemptId);

  Stream<AssessmentAttemptEvent> streamSessionEvents(String sessionId);
}

class AssessmentService {
  const AssessmentService(this._store);

  final AssessmentStore _store;

  Future<AssessmentOverview> overview(UserModel actor) {
    _requireStudent(actor);
    return _store.overview(actor.id);
  }

  Future<AssessmentAttempt> start(UserModel actor, String worldId) {
    _requireStudent(actor);
    _requiredId(worldId, 'worldId');
    return _store.start(actor.id, worldId);
  }

  Future<AssessmentAttempt> loadAttempt(UserModel actor, String attemptId) {
    _requireStudent(actor);
    _requiredId(attemptId, 'attemptId');
    return _store.loadAttempt(actor.id, attemptId);
  }

  Future<AssessmentResult> submit(
    UserModel actor,
    String attemptId,
    Map<String, List<String>> answers,
  ) {
    _requireStudent(actor);
    _requiredId(attemptId, 'attemptId');
    for (final entry in answers.entries) {
      _requiredId(entry.key, 'questionId');
      if (entry.value.toSet().length != entry.value.length ||
          entry.value.any((id) => id.trim().isEmpty)) {
        throw const CatalogException(
          'invalid_answers',
          'Las opciones seleccionadas deben ser únicas y válidas.',
        );
      }
    }
    return _store.submit(actor.id, attemptId, answers);
  }

  Future<void> saveDraftAnswers(
    UserModel actor,
    String attemptId,
    Map<String, List<String>> answers,
  ) {
    _requireStudent(actor);
    _requiredId(attemptId, 'attemptId');
    return _store.saveDraftAnswers(actor.id, attemptId, answers);
  }

  Future<AssessmentAttempt> recordIncident(
    UserModel actor,
    String attemptId, {
    required String type,
    required String message,
  }) {
    _requireStudent(actor);
    _requiredId(attemptId, 'attemptId');
    _requiredId(type, 'type');
    _requiredId(message, 'message');
    return _store.recordIncident(
      actor.id,
      attemptId,
      type: type,
      message: message,
    );
  }

  Future<AssessmentResult> loadResult(UserModel actor, String attemptId) {
    _requireStudent(actor);
    _requiredId(attemptId, 'attemptId');
    return _store.loadResult(actor.id, attemptId);
  }

  Future<TeacherReport> report(
    UserModel actor, {
    String? studentId,
    String? worldId,
    String? topicId,
  }) {
    _requireTeacher(actor);
    return _store.report(
      studentId: _emptyToNull(studentId),
      worldId: _emptyToNull(worldId),
      topicId: _emptyToNull(topicId),
    );
  }

  Future<AssessmentSessionOverview> sessionOverview(UserModel actor) {
    _requireTeacher(actor);
    return _store.sessionOverview();
  }

  Future<AssessmentWorldSettings> saveSettings(
    UserModel actor,
    AssessmentWorldSettings settings,
  ) {
    _requireTeacher(actor);
    _requiredId(settings.worldId, 'worldId');
    if (settings.durationMinutes < 1 || settings.durationMinutes > 240) {
      throw const CatalogException(
        'validation_failed',
        'La duración debe estar entre 1 y 240 minutos.',
      );
    }
    if (settings.maxIncidents < 1 || settings.maxIncidents > 20) {
      throw const CatalogException(
        'validation_failed',
        'El máximo de incidentes debe estar entre 1 y 20.',
      );
    }
    if (settings.returnGraceSeconds < 1 || settings.returnGraceSeconds > 120) {
      throw const CatalogException(
        'validation_failed',
        'La gracia de retorno debe estar entre 1 y 120 segundos.',
      );
    }
    return _store.saveSettings(settings);
  }

  Future<AssessmentSession> openSession(UserModel actor, String worldId) {
    _requireTeacher(actor);
    _requiredId(worldId, 'worldId');
    return _store.openSession(actor.id, worldId);
  }

  Future<AssessmentSession> closeSession(UserModel actor, String sessionId) {
    _requireTeacher(actor);
    _requiredId(sessionId, 'sessionId');
    return _store.closeSession(actor.id, sessionId);
  }

  Future<AssessmentSession> reactivateAttempt(
    UserModel actor,
    String attemptId, {
    required String reason,
  }) {
    _requireTeacher(actor);
    _requiredId(attemptId, 'attemptId');
    _requiredId(reason, 'reason');
    return _store.reactivateAttempt(actor.id, attemptId, reason: reason);
  }

  Future<AssessmentDetailReport> detailReport(
    UserModel actor,
    String attemptId,
  ) {
    _requireTeacher(actor);
    _requiredId(attemptId, 'attemptId');
    return _store.detailReport(attemptId);
  }

  Stream<AssessmentAttemptEvent> streamSessionEvents(
    UserModel actor,
    String sessionId,
  ) {
    _requireTeacher(actor);
    _requiredId(sessionId, 'sessionId');
    return _store.streamSessionEvents(sessionId);
  }

  void _requireStudent(UserModel actor) {
    if (actor.role != UserRole.student) {
      throw const CatalogException(
        'forbidden',
        'Los parciales requieren una cuenta estudiantil.',
      );
    }
  }

  void _requireTeacher(UserModel actor) {
    if (actor.role != UserRole.teacher) {
      throw const CatalogException(
        'forbidden',
        'Los informes requieren una cuenta docente.',
      );
    }
  }

  void _requiredId(String value, String name) {
    if (value.trim().isEmpty) {
      throw CatalogException(
        'invalid_identifier',
        'El campo $name es obligatorio.',
      );
    }
  }

  String? _emptyToNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
