import '../../core/models/user_model.dart';
import '../../core/repositories/catalog_repository.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    required this.expiresAt,
  });

  final UserModel user;
  final String token;
  final DateTime expiresAt;
}

abstract interface class IdentityStore {
  Future<bool> isBootstrapRequired();

  Future<AuthSession> bootstrapTeacher({
    required String username,
    required String displayName,
    required String password,
  });

  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<UserModel?> authenticate(String token);

  Future<void> logout(String token);

  Future<List<UserModel>> listUsers();

  Future<UserModel> createStudent({
    required String username,
    required String displayName,
    required String password,
  });
}

class IdentityService {
  const IdentityService(this._store);

  final IdentityStore _store;

  Future<bool> isBootstrapRequired() => _store.isBootstrapRequired();

  Future<AuthSession> bootstrapTeacher({
    required String username,
    required String displayName,
    required String password,
  }) {
    _validateRegistration(username, displayName, password);
    return _store.bootstrapTeacher(
      username: _normalizeUsername(username),
      displayName: displayName.trim(),
      password: password,
    );
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) {
    if (username.trim().isEmpty || password.isEmpty) {
      throw const CatalogException(
        'invalid_credentials',
        'Usuario o clave incorrectos.',
      );
    }
    return _store.login(
      username: _normalizeUsername(username),
      password: password,
    );
  }

  Future<UserModel?> authenticate(String? token) {
    if (token == null || token.isEmpty) return Future.value();
    return _store.authenticate(token);
  }

  Future<void> logout(String? token) {
    if (token == null || token.isEmpty) return Future.value();
    return _store.logout(token);
  }

  Future<List<UserModel>> listUsers(UserModel actor) {
    _requireTeacher(actor);
    return _store.listUsers();
  }

  Future<UserModel> createStudent({
    required UserModel actor,
    required String username,
    required String displayName,
    required String password,
  }) {
    _requireTeacher(actor);
    _validateRegistration(username, displayName, password);
    return _store.createStudent(
      username: _normalizeUsername(username),
      displayName: displayName.trim(),
      password: password,
    );
  }

  void _requireTeacher(UserModel actor) {
    if (actor.role != UserRole.teacher) {
      throw const CatalogException(
        'forbidden',
        'Esta operación requiere el rol docente.',
      );
    }
  }

  void _validateRegistration(
    String username,
    String displayName,
    String password,
  ) {
    final normalized = _normalizeUsername(username);
    if (!RegExp(r'^[a-z0-9._-]{3,32}$').hasMatch(normalized)) {
      throw const CatalogException(
        'invalid_username',
        'El usuario debe tener de 3 a 32 caracteres válidos.',
      );
    }
    if (displayName.trim().length < 2 || displayName.trim().length > 80) {
      throw const CatalogException(
        'invalid_display_name',
        'El nombre debe tener entre 2 y 80 caracteres.',
      );
    }
    if (password.length < 10 || password.length > 128) {
      throw const CatalogException(
        'invalid_password',
        'La clave debe tener entre 10 y 128 caracteres.',
      );
    }
  }

  String _normalizeUsername(String value) => value.trim().toLowerCase();
}
