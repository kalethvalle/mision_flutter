import 'package:flutter/foundation.dart';

import '../models/assessment_model.dart';
import '../models/authoring_model.dart';
import '../repositories/catalog_repository.dart';

enum AssessmentLoadState { loading, ready, failure }

class AssessmentStore extends ChangeNotifier {
  AssessmentStore(this._repository);

  final FlutterQuestRepository _repository;

  AssessmentLoadState _state = AssessmentLoadState.loading;
  AssessmentOverview _overview = const AssessmentOverview(
    availability: [],
    history: [],
  );
  AssessmentAttempt? _attempt;
  AssessmentResult? _result;
  final Map<String, Set<String>> _answers = {};
  String? _error;
  bool _isBusy = false;

  AssessmentLoadState get state => _state;
  AssessmentOverview get overview => _overview;
  AssessmentAttempt? get attempt => _attempt;
  AssessmentResult? get result => _result;
  String? get error => _error;
  bool get isBusy => _isBusy;
  Map<String, Set<String>> get answers => Map.unmodifiable(_answers);

  AssessmentAvailability? availabilityFor(String worldId) => _overview
      .availability
      .where((item) => item.worldId == worldId)
      .firstOrNull;

  Future<void> load() async {
    _state = AssessmentLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      _overview = await _repository.getAssessmentOverview();
      _state = AssessmentLoadState.ready;
    } on Object catch (error) {
      _state = AssessmentLoadState.failure;
      _error = _messageFor(error);
    }
    notifyListeners();
  }

  Future<bool> start(String worldId) async {
    return _run(() async {
      _attempt = await _repository.startAssessment(worldId);
      _result = null;
      _answers.clear();
      _overview = await _repository.getAssessmentOverview();
    });
  }

  Future<bool> resume(String attemptId) async {
    return _run(() async {
      _attempt = await _repository.getAssessmentAttempt(attemptId);
      _result = null;
      _answers.clear();
      for (final entry in _attempt!.draftAnswers.entries) {
        _answers[entry.key] = entry.value.toSet();
      }
    });
  }

  Future<bool> showResult(String attemptId) async {
    return _run(() async {
      _result = await _repository.getAssessmentResult(attemptId);
      _attempt = null;
      _answers.clear();
    });
  }

  void toggle(AssessmentQuestion question, String optionId) {
    final selected = _answers.putIfAbsent(question.id, () => <String>{});
    if (question.type == QuestionType.single) {
      if (selected.contains(optionId)) {
        selected.clear();
      } else {
        selected
          ..clear()
          ..add(optionId);
      }
    } else if (!selected.add(optionId)) {
      selected.remove(optionId);
    }
    notifyListeners();
    final current = _attempt;
    if (current != null) {
      _repository.saveAssessmentDraft(current.id, {
        for (final entry in _answers.entries) entry.key: entry.value.toList(),
      });
    }
  }

  Future<void> recordIncident(String type, String message) async {
    final current = _attempt;
    if (current == null) return;
    try {
      _attempt = await _repository.recordAssessmentIncident(
        current.id,
        type: type,
        message: message,
      );
    } on Object catch (error) {
      _error = _messageFor(error);
    }
    notifyListeners();
  }

  Future<bool> submit() async {
    final current = _attempt;
    if (current == null) return false;
    return _run(() async {
      _result = await _repository.submitAssessment(current.id, {
        for (final entry in _answers.entries) entry.key: entry.value.toList(),
      });
      _attempt = null;
      _answers.clear();
      _overview = await _repository.getAssessmentOverview();
    });
  }

  void clearActive() {
    _attempt = null;
    _result = null;
    _answers.clear();
    _error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() operation) async {
    if (_isBusy) return false;
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } on Object catch (error) {
      _error = _messageFor(error);
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is CatalogException) return error.message;
    return 'No fue posible completar la operación del parcial.';
  }
}

class AssessmentSessionStore extends ChangeNotifier {
  AssessmentSessionStore(this._repository);

  final FlutterQuestRepository _repository;
  AssessmentSessionOverview? _overview;
  String? _error;
  bool _loading = false;

  AssessmentSessionOverview? get overview => _overview;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _overview = await _repository.getAssessmentSessions();
    } on Object catch (error) {
      _error = error is CatalogException
          ? error.message
          : 'No fue posible cargar las sesiones.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveSettings(AssessmentWorldSettings settings) async {
    await _run(() => _repository.saveAssessmentSettings(settings));
  }

  Future<void> open(String worldId) async {
    await _run(() => _repository.openAssessmentSession(worldId));
  }

  Future<void> close(String sessionId) async {
    await _run(() => _repository.closeAssessmentSession(sessionId));
  }

  Future<void> reactivate(String attemptId, String reason) async {
    await _run(
      () => _repository.reactivateAssessmentAttempt(attemptId, reason: reason),
    );
  }

  Future<void> _run(Future<Object?> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _overview = await _repository.getAssessmentSessions();
    } on Object catch (error) {
      _error = error is CatalogException
          ? error.message
          : 'No fue posible actualizar el parcial.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

class ReportStore extends ChangeNotifier {
  ReportStore(this._repository);

  final FlutterQuestRepository _repository;

  TeacherReport? _report;
  String? _error;
  bool _loading = false;

  TeacherReport? get report => _report;
  String? get error => _error;
  bool get loading => _loading;
  AssessmentDetailReport? _detail;
  AssessmentDetailReport? get detail => _detail;

  Future<void> load({
    String? studentId,
    String? worldId,
    String? topicId,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _report = await _repository.getTeacherReport(
        studentId: studentId,
        worldId: worldId,
        topicId: topicId,
      );
    } on Object catch (error) {
      _error = error is CatalogException
          ? error.message
          : 'No fue posible cargar el informe.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(String attemptId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _repository.getAssessmentDetailReport(attemptId);
    } on Object catch (error) {
      _error = error is CatalogException
          ? error.message
          : 'No fue posible cargar el detalle.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
