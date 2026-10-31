import 'dart:async';
import 'dart:io';

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
import 'package:mision_flutter/server/server_handler.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> arguments) async {
  final options = _ServerOptions.parse(arguments);
  CatalogDatabase? catalogDatabase;
  try {
    catalogDatabase = CatalogDatabase.open(options.databasePath);
    final catalogRepository = SqliteCatalogRepository(catalogDatabase.database);
    final identityStore = SqliteIdentityStore(catalogDatabase.database);
    final progressStore = SqliteProgressStore(catalogDatabase.database);
    final identityService = IdentityService(identityStore);
    final security = ApiSecurity(identityService);
    final apiHandler = createApiHandler(
      identityApi: IdentityApi(
        identityService: identityService,
        security: security,
      ),
      catalogApi: CatalogApi(
        catalogService: CatalogService(catalogRepository),
        security: security,
        databaseIsHealthy: () => catalogRepository.isHealthy,
      ),
      trainingApi: TrainingApi(
        progressService: ProgressService(progressStore, progressStore),
        security: security,
      ),
    );
    final handler = createServerHandler(
      apiHandler: apiHandler,
      webRoot: options.webRoot,
    );
    final server = await shelf_io.serve(handler, options.host, options.port);
    stdout.writeln(
      'Flutter Quest disponible en http://${server.address.host}:${server.port}',
    );
    stdout.writeln('SQLite: ${catalogDatabase.databasePath}');

    final shutdown = Completer<void>();
    final subscriptions = <StreamSubscription<ProcessSignal>>[
      ProcessSignal.sigint.watch().listen((_) {
        if (!shutdown.isCompleted) shutdown.complete();
      }),
      ProcessSignal.sigterm.watch().listen((_) {
        if (!shutdown.isCompleted) shutdown.complete();
      }),
    ];
    await shutdown.future;
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
    await server.close(force: true);
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('No fue posible iniciar Flutter Quest: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  } finally {
    catalogDatabase?.close();
  }
}

class _ServerOptions {
  const _ServerOptions({
    required this.host,
    required this.port,
    required this.databasePath,
    required this.webRoot,
  });

  final String host;
  final int port;
  final String databasePath;
  final String webRoot;

  static _ServerOptions parse(List<String> arguments) {
    var host = '127.0.0.1';
    var port = 8080;
    var databasePath = 'data/flutter_quest.sqlite3';
    var webRoot = 'build/web';

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      if (!argument.startsWith('--') || index + 1 >= arguments.length) {
        throw FormatException('Argumento inválido: $argument');
      }
      final value = arguments[++index];
      switch (argument) {
        case '--host':
          host = value;
        case '--port':
          port = int.parse(value);
        case '--database':
          databasePath = value;
        case '--web-root':
          webRoot = value;
        default:
          throw FormatException('Argumento desconocido: $argument');
      }
    }
    if (port < 1 || port > 65535) {
      throw const FormatException('El puerto debe estar entre 1 y 65535.');
    }
    return _ServerOptions(
      host: host,
      port: port,
      databasePath: databasePath,
      webRoot: webRoot,
    );
  }
}
