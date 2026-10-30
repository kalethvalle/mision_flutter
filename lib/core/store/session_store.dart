import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repositories/catalog_repository.dart';

enum SessionState {
  loading,
  bootstrapRequired,
  signedOut,
  authenticated,
  failure,
}

class SessionStore extends ChangeNotifier {
  SessionStore(this._repository);

  final FlutterQuestRepository _repository;

  SessionState _state = SessionState.loading;
  UserModel? _user;
  List<UserModel> _users = const [];
  String? _error;
  bool _isSubmitting = false;

  SessionState get state => _state;
  UserModel? get user => _user;
  List<UserModel> get users => _users;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;

  Future<void> initialize() async {
    _state = SessionState.loading;
    _error = null;
    notifyListeners();
    try {
      final snapshot = await _repository.getAuthStatus();
      _user = snapshot.user;
      _state = snapshot.bootstrapRequired
          ? SessionState.bootstrapRequired
          : snapshot.user == null
          ? SessionState.signedOut
          : SessionState.authenticated;
      if (_user?.role == UserRole.teacher) await _loadUsers();
    } on Object catch (error) {
      _state = SessionState.failure;
      _error = _messageFor(error);
    }
    notifyListeners();
  }

  Future<bool> bootstrapTeacher({
    required String username,
    required String displayName,
    required String password,
  }) async {
    return _submit(() async {
      _user = await _repository.bootstrapTeacher(
        username: username,
        displayName: displayName,
        password: password,
      );
      _state = SessionState.authenticated;
      await _loadUsers();
    });
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    return _submit(() async {
      _user = await _repository.login(username: username, password: password);
      _state = SessionState.authenticated;
      if (_user?.role == UserRole.teacher) await _loadUsers();
    });
  }

  Future<void> logout() async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.logout();
    } on Object {
      // El estado local se descarta incluso si la sesión ya venció.
    }
    _user = null;
    _users = const [];
    _error = null;
    _isSubmitting = false;
    _state = SessionState.signedOut;
    notifyListeners();
  }

  Future<bool> createStudent({
    required String username,
    required String displayName,
    required String password,
  }) async {
    return _submit(() async {
      await _repository.createStudent(
        username: username,
        displayName: displayName,
        password: password,
      );
      await _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    _users = await _repository.listUsers();
  }

  Future<bool> _submit(Future<void> Function() operation) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      await operation();
      return true;
    } on Object catch (error) {
      _error = _messageFor(error);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is CatalogException) return error.message;
    return 'No fue posible conectar con el servidor local.';
  }
}
