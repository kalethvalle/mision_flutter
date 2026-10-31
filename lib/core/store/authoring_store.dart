import 'package:flutter/foundation.dart';

import '../models/authoring_model.dart';
import '../repositories/catalog_repository.dart';

enum AuthoringState { loading, ready, failure }

class AuthoringStore extends ChangeNotifier {
  AuthoringStore(this._repository);

  final FlutterQuestRepository _repository;

  AuthoringState _state = AuthoringState.loading;
  AuthoringCatalog? _catalog;
  String? _error;
  bool _isSaving = false;

  AuthoringState get state => _state;
  AuthoringCatalog? get catalog => _catalog;
  String? get error => _error;
  bool get isSaving => _isSaving;

  List<AuthoringWorld> get worlds => _catalog?.worlds ?? const [];
  List<AuthoringTopic> get topics => _catalog?.topics ?? const [];
  List<AuthoringMission> get missions => _catalog?.missions ?? const [];
  List<AuthoringQuestion> get questions => _catalog?.questions ?? const [];
  List<String> get previewTypes => _catalog?.previewTypes ?? const [];

  Future<void> load() async {
    _state = AuthoringState.loading;
    _error = null;
    notifyListeners();
    try {
      _catalog = await _repository.getAuthoringCatalog();
      _state = AuthoringState.ready;
    } on Object catch (error) {
      _state = AuthoringState.failure;
      _error = _messageFor(error);
    }
    notifyListeners();
  }

  Future<bool> saveWorld(AuthoringWorld world) =>
      _save(() => _repository.saveWorld(world));

  Future<bool> saveTopic(AuthoringTopic topic) =>
      _save(() => _repository.saveTopic(topic));

  Future<bool> saveMission(AuthoringMission mission) =>
      _save(() => _repository.saveMission(mission));

  Future<bool> saveQuestion(AuthoringQuestion question) =>
      _save(() => _repository.saveQuestion(question));

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

  Future<bool> _save(Future<Object> Function() operation) async {
    if (_isSaving) return false;
    _isSaving = true;
    _error = null;
    notifyListeners();
    try {
      await operation();
      _catalog = await _repository.getAuthoringCatalog();
      _state = AuthoringState.ready;
      return true;
    } on Object catch (error) {
      _error = _messageFor(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is CatalogException) return error.message;
    return 'No fue posible guardar el contenido.';
  }
}
