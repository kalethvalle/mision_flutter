# Plan - MongoDB runtime analytics deployment

## Implementacion

1. Crear configuracion de backend analitico por variables de entorno.
2. Agregar `MongoAnalyticsStore` como implementacion de `AnalyticsStore`.
3. Mantener `SqliteAnalyticsStore` como fuente de calculo y backend por defecto.
4. Conectar la seleccion de store en `bin/server.dart`.
5. Agregar dependencia Dart para MongoDB.
6. Agregar pruebas unitarias de configuracion.
7. Agregar Docker Compose para modo SQLite y modo MongoDB analitico.
8. Documentar MER SQL, modelo documental MongoDB y despliegue.
9. Actualizar `.specs/context.md`.

## Archivos esperados

- `pubspec.yaml`
- `bin/server.dart`
- `lib/server/analytics/analytics_backend_config.dart`
- `lib/server/repositories/mongo_analytics_store.dart`
- `test/analytics_backend_config_test.dart`
- `compose.sqlite.yaml`
- `compose.mongo-analytics.yaml`
- `.env.example`
- `docs/architecture/analytics-data-models.md`
- `docs/despliegue-analytics-docker.md`
- `.specs/context.md`

## Trazabilidad

- R1, R3: `MongoAnalyticsStore` devuelve `AnalyticsDashboard` desde snapshot.
- R2: configuracion por defecto en SQLite.
- R4, R5: refresh Mongo reconstruye desde SQLite y publica `current` al final.
- R6: compose SQLite y compose MongoDB.
- R7: documentos de arquitectura y despliegue.

## Validacion

- `flutter test test/analytics_backend_config_test.dart`
- `flutter test`
- `flutter analyze --no-fatal-infos`
- `dart build cli --target bin/server.dart -o /tmp/flutter_quest_server_mongo_check`
- `flutter build web --release`
- `docker-compose -f compose.sqlite.yaml config`
- `docker-compose --env-file .env.example -f compose.mongo-analytics.yaml config`

## Compatibilidad

- No hay migracion SQLite nueva.
- La UI no cambia.
- Si MongoDB no se configura, no se abre conexion MongoDB.
- Las colecciones MongoDB son derivadas y reconstruibles.

## Estado

- Implementado y verificado.

## Evidencia

- `flutter test test/analytics_backend_config_test.dart`: 4 pruebas pasaron.
- `flutter test`: 43 pruebas pasaron.
- `flutter analyze --no-fatal-infos`: completo con 5 infos preexistentes de UI/repositorio.
- `dart build cli --target bin/server.dart -o /tmp/flutter_quest_server_mongo_check`: genero bundle del servidor.
- `flutter build web --release`: genero `build/web`.
- `docker-compose -f compose.sqlite.yaml config`: configuracion valida.
- `docker-compose --env-file .env.example -f compose.mongo-analytics.yaml config`: configuracion valida.
