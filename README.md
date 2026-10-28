# Flutter Quest (`mision_flutter`)

Aplicación para practicar Dart y Flutter mediante mundos y misiones interactivas.
Incluye dos mundos, nueve temas y nueve misiones. Flutter Web consulta el
catálogo mediante una API Dart local; el contenido vive en SQLite y la
comprobación de respuestas ocurre en el servidor. El progreso todavía permanece
en memoria y no existen cuentas, editor docente ni parciales.

La [planificación SDD de las 12 historias de usuario](docs/stories-users.md)
describe la evolución del producto. Las features verificadas se registran en
[`.specs/context.md`](.specs/context.md).

## Ejecutar la versión web local

Requiere Flutter y Dart 3.13 o posteriores. Desde la raíz del proyecto:

```sh
flutter doctor
flutter pub get
flutter build web
dart run bin/server.dart
```

Después abre `http://127.0.0.1:8080`. El primer arranque crea
`data/flutter_quest.sqlite3`, aplica las migraciones y carga el catálogo inicial.
`data/` está excluido de Git. Reiniciar el servidor no duplica el contenido.

El servidor admite configuración explícita:

```sh
dart run bin/server.dart \
  --host 127.0.0.1 \
  --port 8080 \
  --database data/flutter_quest.sqlite3 \
  --web-root build/web
```

La configuración de `sqlite3` usa la biblioteca del sistema para evitar
descargas nativas durante el build: `libsqlite3` en macOS/Linux y
`winsqlite3` en Windows.

## Arquitectura web local

```text
Flutter Web → /api/v1 → casos de uso → repositorios → SQLite
```

El mismo proceso Dart sirve `build/web` y la API desde `127.0.0.1`, por lo que
el navegador no abre SQLite directamente y no se requiere CORS. Los endpoints
de lectura no incluyen la solución; `POST /api/v1/missions/:id/check` realiza
la comprobación en el servidor. Si la API o la base no están disponibles, la
interfaz muestra un error y permite reintentar.

## Verificación

```sh
flutter analyze --no-fatal-infos
flutter test
flutter build web
```

Las pruebas cubren migraciones, semilla idempotente, repositorios SQLite y HTTP,
API, contenido pedagógico y presentación responsive.

## Preparar Android

El proyecto Flutter conserva sus plataformas móviles, pero Android no se
declara verificado en esta fase. La aplicación actual usa el adaptador HTTP
pensado para el servidor web local; una fase posterior añadirá un adaptador
SQLite nativo para Android reutilizando los modelos y contratos del catálogo.

Consulta la [documentación oficial de compilación Android](https://docs.flutter.dev/deployment/android).
