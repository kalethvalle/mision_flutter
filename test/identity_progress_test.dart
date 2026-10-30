import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/application/identity/identity_service.dart';
import 'package:mision_flutter/core/models/user_model.dart';
import 'package:mision_flutter/core/repositories/catalog_repository.dart';
import 'package:mision_flutter/server/database/catalog_database.dart';
import 'package:mision_flutter/server/database/catalog_seed.dart';
import 'package:mision_flutter/server/repositories/sqlite_identity_store.dart';
import 'package:mision_flutter/server/repositories/sqlite_progress_store.dart';
import 'package:mision_flutter/server/security/security_service.dart';

void main() {
  test('Argon2id usa sal individual y verifica sin texto plano', () async {
    final hasher = PasswordHasher(memory: 64, iterations: 1);
    final first = await hasher.hash('student1234');
    final second = await hasher.hash('student1234');

    expect(first.algorithm, 'argon2id');
    expect(first.salt, isNot(second.salt));
    expect(first.hash, isNot(second.hash));
    expect(first.hash, isNot(contains('student1234')));
    expect(await hasher.verify('student1234', first), isTrue);
    expect(await hasher.verify('incorrecta', first), isFalse);
  });

  group('identidad y progreso SQLite', () {
    late Directory tempDirectory;
    late String databasePath;
    late CatalogDatabase database;
    late SqliteIdentityStore identityStore;
    late IdentityService identity;
    late SqliteProgressStore progress;
    var now = DateTime.utc(2026, 10, 30, 12);

    setUp(() {
      tempDirectory = Directory.systemTemp.createTempSync(
        'flutter_quest_identity_',
      );
      databasePath = '${tempDirectory.path}/app.sqlite3';
      database = CatalogDatabase.open(databasePath);
      identityStore = SqliteIdentityStore(
        database.database,
        passwordHasher: PasswordHasher(memory: 64, iterations: 1),
        clock: () => now,
        sessionDuration: const Duration(hours: 1),
      );
      identity = IdentityService(identityStore);
      progress = SqliteProgressStore(database.database, clock: () => now);
    });

    tearDown(() {
      database.close();
      tempDirectory.deleteSync(recursive: true);
    });

    test('crea bootstrap único, hash y sesión opaca expirable', () async {
      expect(await identity.isBootstrapRequired(), isTrue);
      final session = await identity.bootstrapTeacher(
        username: 'Teacher',
        displayName: 'Docente Principal',
        password: 'teacher1234',
      );
      expect(session.user.role, UserRole.teacher);
      expect(await identity.isBootstrapRequired(), isFalse);
      expect(
        (await identity.authenticate(session.token))?.toJson(),
        session.user.toJson(),
      );

      final stored = database.database.select('SELECT * FROM users').single;
      expect(stored['username_normalized'], 'teacher');
      expect(stored['password_hash'], isNot('teacher1234'));
      expect(stored['password_salt'], isNot(isEmpty));
      final storedSession = database.database
          .select('SELECT * FROM sessions')
          .single;
      expect(storedSession['token_hash'], isNot(session.token));

      expect(
        identity.bootstrapTeacher(
          username: 'other',
          displayName: 'Otro Docente',
          password: 'teacher5678',
        ),
        throwsA(
          isA<CatalogException>().having(
            (error) => error.code,
            'code',
            'bootstrap_completed',
          ),
        ),
      );

      now = now.add(const Duration(hours: 2));
      expect(await identity.authenticate(session.token), isNull);
    });

    test('aísla estudiantes y conserva desbloqueo tras reiniciar', () async {
      final teacherSession = await identity.bootstrapTeacher(
        username: 'teacher',
        displayName: 'Docente Principal',
        password: 'teacher1234',
      );
      final firstStudent = await identity.createStudent(
        actor: teacherSession.user,
        username: 'ana',
        displayName: 'Ana',
        password: 'student1234',
      );
      final secondStudent = await identity.createStudent(
        actor: teacherSession.user,
        username: 'luis',
        displayName: 'Luis',
        password: 'student5678',
      );

      final initial = await progress.loadProgress(firstStudent.id);
      expect(initial.mission('w1_m1')!.isUnlocked, isTrue);
      expect(initial.mission('w1_m2')!.isUnlocked, isFalse);
      expect(initial.world('world_2')!.isUnlocked, isFalse);

      expect(
        progress.checkAndRecord(
          userId: firstStudent.id,
          missionId: 'w1_m2',
          optionId: 'final',
          hintUsed: false,
        ),
        throwsA(
          isA<CatalogException>().having(
            (error) => error.code,
            'code',
            'mission_locked',
          ),
        ),
      );
      expect(_count(database, 'training_attempts'), 0);

      for (final mission in seedMissions.where(
        (mission) => mission.worldId == 'world_1',
      )) {
        final correct = mission.options.singleWhere(
          (option) => option.isCorrect,
        );
        await progress.checkAndRecord(
          userId: firstStudent.id,
          missionId: mission.id,
          optionId: correct.id,
          hintUsed: mission.id == 'w1_m1',
        );
        now = now.add(const Duration(minutes: 1));
      }

      expect(
        (await progress.loadProgress(firstStudent.id))
            .world('world_2')!
            .isUnlocked,
        isTrue,
      );
      expect(
        (await progress.loadProgress(secondStudent.id))
            .world('world_2')!
            .isUnlocked,
        isFalse,
      );
      expect(_count(database, 'training_attempts'), 5);
      expect(_count(database, 'mission_progress'), 5);
      expect(
        database.database.select(
          'SELECT hint_used FROM training_attempts WHERE mission_id = ?',
          ['w1_m1'],
        ).single['hint_used'],
        1,
      );

      for (final mission in seedMissions.where(
        (mission) => mission.worldId == 'world_2',
      )) {
        final correct = mission.options.singleWhere(
          (option) => option.isCorrect,
        );
        await progress.checkAndRecord(
          userId: firstStudent.id,
          missionId: mission.id,
          optionId: correct.id,
          hintUsed: false,
        );
        now = now.add(const Duration(minutes: 1));
      }
      expect(_count(database, 'training_attempts'), 9);
      expect(_count(database, 'mission_progress'), 9);

      database.close();
      database = CatalogDatabase.open(databasePath);
      progress = SqliteProgressStore(database.database, clock: () => now);
      final restored = await progress.loadProgress(firstStudent.id);
      expect(restored.world('world_2')!.isUnlocked, isTrue);
      expect(restored.worlds.first.completedMissions, 5);
      expect(restored.worlds.last.completedMissions, 4);
      expect(restored.missions.every((mission) => mission.isCompleted), isTrue);
    });
  });
}

int _count(CatalogDatabase database, String table) {
  const allowed = {'training_attempts', 'mission_progress'};
  if (!allowed.contains(table)) throw ArgumentError.value(table);
  return database.database
          .select('SELECT COUNT(*) AS total FROM $table')
          .single['total']!
      as int;
}
