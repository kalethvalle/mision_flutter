import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/application/catalog/catalog_service.dart';
import 'package:mision_flutter/application/identity/identity_service.dart';
import 'package:mision_flutter/application/progress/progress_service.dart';
import 'package:mision_flutter/server/api/api_security.dart';
import 'package:mision_flutter/server/api/app_api.dart';
import 'package:mision_flutter/server/api/catalog_api.dart';
import 'package:mision_flutter/server/api/identity_api.dart';
import 'package:mision_flutter/server/api/training_api.dart';
import 'package:mision_flutter/server/database/catalog_database.dart';
import 'package:mision_flutter/server/repositories/sqlite_catalog_repository.dart';
import 'package:mision_flutter/server/repositories/sqlite_identity_store.dart';
import 'package:mision_flutter/server/repositories/sqlite_progress_store.dart';
import 'package:mision_flutter/server/security/security_service.dart';
import 'package:shelf/shelf.dart';

void main() {
  late Directory tempDirectory;
  late CatalogDatabase database;
  late Handler api;

  setUp(() {
    tempDirectory = Directory.systemTemp.createTempSync('flutter_quest_api_');
    database = CatalogDatabase.open('${tempDirectory.path}/catalog.sqlite3');
    final catalog = SqliteCatalogRepository(database.database);
    final identityStore = SqliteIdentityStore(
      database.database,
      passwordHasher: PasswordHasher(memory: 64, iterations: 1),
    );
    final identity = IdentityService(identityStore);
    final security = ApiSecurity(identity);
    final progress = SqliteProgressStore(database.database);
    api = createApiHandler(
      identityApi: IdentityApi(identityService: identity, security: security),
      catalogApi: CatalogApi(
        catalogService: CatalogService(catalog),
        security: security,
        databaseIsHealthy: () => catalog.isHealthy,
      ),
      trainingApi: TrainingApi(
        progressService: ProgressService(progress, progress),
        security: security,
      ),
    );
  });

  tearDown(() {
    database.close();
    tempDirectory.deleteSync(recursive: true);
  });

  test('bootstrap crea una sesión y protege el catálogo', () async {
    final health = await api(_request('GET', '/api/v1/health'));
    expect(health.statusCode, 200);
    final unauthorized = await api(_request('GET', '/api/v1/worlds'));
    expect(unauthorized.statusCode, 401);

    final bootstrap = await api(
      _post('/api/v1/auth/bootstrap', {
        'username': 'teacher',
        'displayName': 'Docente Principal',
        'password': 'teacher1234',
      }),
    );
    expect(bootstrap.statusCode, 201);
    final teacherCookie = _cookie(bootstrap);
    final bootstrapBody = await bootstrap.readAsString();
    expect(bootstrapBody, isNot(contains('teacher1234')));
    expect(bootstrapBody, isNot(contains('token')));

    final repeated = await api(
      _post('/api/v1/auth/bootstrap', {
        'username': 'other',
        'displayName': 'Otro Docente',
        'password': 'teacher5678',
      }),
    );
    expect(repeated.statusCode, 409);

    final worlds = await api(
      _request('GET', '/api/v1/worlds', cookie: teacherCookie),
    );
    expect(worlds.statusCode, 200);
    final body = await worlds.readAsString();
    expect((jsonDecode(body) as Map<String, Object?>)['worlds'], hasLength(2));
    expect(body, isNot(contains('password_hash')));
    expect(body, isNot(contains('isCorrect')));
  });

  test('docente crea estudiante y el rol limita operaciones', () async {
    final teacherCookie = await _bootstrapTeacher(api);
    final created = await api(
      _post('/api/v1/users', {
        'username': 'ana',
        'displayName': 'Ana Estudiante',
        'password': 'student1234',
      }, cookie: teacherCookie),
    );
    expect(created.statusCode, 201);

    final login = await api(
      _post('/api/v1/auth/login', {
        'username': 'ANA',
        'password': 'student1234',
      }),
    );
    expect(login.statusCode, 200);
    final studentCookie = _cookie(login);
    expect(
      (await api(_request('GET', '/api/v1/users', cookie: studentCookie)))
          .statusCode,
      403,
    );
    expect(
      (await api(_request('GET', '/api/v1/progress', cookie: teacherCookie)))
          .statusCode,
      403,
    );
    expect(
      (await api(_request('GET', '/api/v1/progress', cookie: studentCookie)))
          .statusCode,
      200,
    );
  });

  test('registra intentos y rechaza saltos de misión', () async {
    final teacherCookie = await _bootstrapTeacher(api);
    final studentCookie = await _createAndLoginStudent(api, teacherCookie);
    final locked = await api(
      _post('/api/v1/missions/w1_m2/check', {
        'optionId': 'final',
        'hintUsed': false,
      }, cookie: studentCookie),
    );
    expect(locked.statusCode, 409);

    final wrong = await api(
      _post('/api/v1/missions/w1_m1/check', {
        'optionId': 'double',
        'hintUsed': true,
      }, cookie: studentCookie),
    );
    expect(wrong.statusCode, 200);
    final correct = await api(
      _post('/api/v1/missions/w1_m1/check', {
        'optionId': 'int',
        'hintUsed': false,
      }, cookie: studentCookie),
    );
    expect(correct.statusCode, 200);
    final result =
        (jsonDecode(await correct.readAsString())
                as Map<String, Object?>)['result']!
            as Map<String, Object?>;
    expect(result['isCorrect'], isTrue);
    final missions =
        (result['progress']! as Map<String, Object?>)['missions']!
            as List<Object?>;
    expect((missions[1]! as Map<String, Object?>)['isUnlocked'], isTrue);

    final attempts = database.database.select('''
      SELECT is_correct, hint_used FROM training_attempts ORDER BY attempted_at
    ''');
    expect(attempts, hasLength(2));
    expect(attempts.first['hint_used'], 1);
    expect(attempts.last['is_correct'], 1);
  });
}

Future<String> _bootstrapTeacher(Handler api) async {
  final response = await api(
    _post('/api/v1/auth/bootstrap', {
      'username': 'teacher',
      'displayName': 'Docente Principal',
      'password': 'teacher1234',
    }),
  );
  expect(response.statusCode, 201);
  return _cookie(response);
}

Future<String> _createAndLoginStudent(Handler api, String teacherCookie) async {
  final created = await api(
    _post('/api/v1/users', {
      'username': 'student',
      'displayName': 'Estudiante Uno',
      'password': 'student1234',
    }, cookie: teacherCookie),
  );
  expect(created.statusCode, 201);
  final login = await api(
    _post('/api/v1/auth/login', {
      'username': 'student',
      'password': 'student1234',
    }),
  );
  expect(login.statusCode, 200);
  return _cookie(login);
}

Request _request(String method, String path, {String? cookie}) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: {'cookie': ?cookie},
  );
}

Request _post(String path, Map<String, Object?> body, {String? cookie}) {
  return Request(
    'POST',
    Uri.parse('http://localhost$path'),
    headers: {'content-type': 'application/json', 'cookie': ?cookie},
    body: jsonEncode(body),
  );
}

String _cookie(Response response) {
  final header = response.headers['set-cookie'];
  expect(header, isNotNull);
  return header!.split(';').first;
}
