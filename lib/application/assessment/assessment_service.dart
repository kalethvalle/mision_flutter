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

  Future<AssessmentResult> loadResult(String userId, String attemptId);

  Future<TeacherReport> report({
    String? studentId,
    String? worldId,
    String? topicId,
  });
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
