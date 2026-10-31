import 'package:sqlite3/sqlite3.dart';

import '../../application/identity/identity_service.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/catalog_repository.dart';
import '../security/security_service.dart';

class SqliteIdentityStore implements IdentityStore {
  SqliteIdentityStore(
    this._database, {
    PasswordHasher? passwordHasher,
    SecureTokenService? tokenService,
    DateTime Function()? clock,
    this.sessionDuration = const Duration(hours: 12),
  }) : _passwordHasher = passwordHasher ?? PasswordHasher(),
       _tokenService = tokenService ?? SecureTokenService(),
       _clock = clock ?? DateTime.now;

  final Database _database;
  final PasswordHasher _passwordHasher;
  final SecureTokenService _tokenService;
  final DateTime Function() _clock;
  final Duration sessionDuration;

  @override
  Future<bool> isBootstrapRequired() async {
    final count =
        _database.select('SELECT COUNT(*) AS total FROM users').single['total']!
            as int;
    return count == 0;
  }

  @override
  Future<AuthSession> bootstrapTeacher({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final digest = await _passwordHasher.hash(password);
    final user = UserModel(
      id: _tokenService.newId(),
      username: username,
      displayName: displayName,
      role: UserRole.teacher,
    );
    final sessionData = await _newSession(user);

    _transaction(() {
      final count =
          _database
                  .select('SELECT COUNT(*) AS total FROM users')
                  .single['total']!
              as int;
      if (count != 0) {
        throw const CatalogException(
          'bootstrap_completed',
          'El docente inicial ya fue creado.',
        );
      }
      _insertUser(user, username, digest);
      _insertSession(sessionData.session, sessionData.tokenHash);
    });
    return sessionData.session;
  }

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final rows = _database.select(
      '''
      SELECT * FROM users
      WHERE username_normalized = ? AND is_active = 1
    ''',
      [username],
    );
    if (rows.isEmpty) throw _invalidCredentials;

    final row = rows.single;
    final verified = await _passwordHasher.verify(
      password,
      PasswordDigest(
        algorithm: row['password_algorithm']! as String,
        salt: row['password_salt']! as String,
        hash: row['password_hash']! as String,
        memory: row['password_memory']! as int,
        iterations: row['password_iterations']! as int,
        parallelism: row['password_parallelism']! as int,
      ),
    );
    if (!verified) throw _invalidCredentials;

    final sessionData = await _newSession(_userFromRow(row));
    _database.execute('DELETE FROM sessions WHERE expires_at <= ?', [
      _now().toIso8601String(),
    ]);
    _insertSession(sessionData.session, sessionData.tokenHash);
    return sessionData.session;
  }

  @override
  Future<UserModel?> authenticate(String token) async {
    final tokenHash = await _tokenService.hashToken(token);
    final now = _now();
    final rows = _database.select(
      '''
      SELECT u.*
      FROM sessions s
      JOIN users u ON u.id = s.user_id
      WHERE s.token_hash = ? AND s.expires_at > ? AND u.is_active = 1
    ''',
      [tokenHash, now.toIso8601String()],
    );
    if (rows.isEmpty) {
      _database.execute('DELETE FROM sessions WHERE token_hash = ?', [
        tokenHash,
      ]);
      return null;
    }
    _database.execute(
      'UPDATE sessions SET last_seen_at = ? WHERE token_hash = ?',
      [now.toIso8601String(), tokenHash],
    );
    return _userFromRow(rows.single);
  }

  @override
  Future<void> logout(String token) async {
    final tokenHash = await _tokenService.hashToken(token);
    _database.execute('DELETE FROM sessions WHERE token_hash = ?', [tokenHash]);
  }

  @override
  Future<List<UserModel>> listUsers() async {
    return _database
        .select('''
      SELECT id, username, display_name, role
      FROM users
      WHERE is_active = 1
      ORDER BY role, display_name COLLATE NOCASE
    ''')
        .map(_userFromRow)
        .toList();
  }

  @override
  Future<UserModel> createStudent({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final digest = await _passwordHasher.hash(password);
    final user = UserModel(
      id: _tokenService.newId(),
      username: username,
      displayName: displayName,
      role: UserRole.student,
    );
    try {
      _insertUser(user, username, digest);
      return user;
    } on SqliteException catch (error) {
      if (error.extendedResultCode == 2067 || error.resultCode == 19) {
        throw const CatalogException(
          'username_taken',
          'El nombre de usuario ya está registrado.',
        );
      }
      rethrow;
    }
  }

  Future<({AuthSession session, String tokenHash})> _newSession(
    UserModel user,
  ) async {
    final token = _tokenService.newToken();
    final session = AuthSession(
      user: user,
      token: token,
      expiresAt: _now().add(sessionDuration),
    );
    return (session: session, tokenHash: await _tokenService.hashToken(token));
  }

  void _insertUser(
    UserModel user,
    String normalizedUsername,
    PasswordDigest digest,
  ) {
    _database.execute(
      '''
      INSERT INTO users(
        id, username, username_normalized, display_name, role,
        password_algorithm, password_salt, password_hash,
        password_memory, password_iterations, password_parallelism,
        created_at, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1)
    ''',
      [
        user.id,
        user.username,
        normalizedUsername,
        user.displayName,
        user.role.wireName,
        digest.algorithm,
        digest.salt,
        digest.hash,
        digest.memory,
        digest.iterations,
        digest.parallelism,
        _now().toIso8601String(),
      ],
    );
  }

  void _insertSession(AuthSession session, String tokenHash) {
    final now = _now();
    _database.execute(
      '''
      INSERT INTO sessions(
        token_hash, user_id, created_at, last_seen_at, expires_at
      ) VALUES (?, ?, ?, ?, ?)
    ''',
      [
        tokenHash,
        session.user.id,
        now.toIso8601String(),
        now.toIso8601String(),
        session.expiresAt.toUtc().toIso8601String(),
      ],
    );
  }

  UserModel _userFromRow(Row row) => UserModel(
    id: row['id']! as String,
    username: row['username']! as String,
    displayName: row['display_name']! as String,
    role: UserRole.fromWireName(row['role']! as String),
  );

  DateTime _now() => _clock().toUtc();

  void _transaction(void Function() operation) {
    _database.execute('BEGIN IMMEDIATE');
    try {
      operation();
      _database.execute('COMMIT');
    } on Object {
      _database.execute('ROLLBACK');
      rethrow;
    }
  }

  static const _invalidCredentials = CatalogException(
    'invalid_credentials',
    'Usuario o clave incorrectos.',
  );
}
