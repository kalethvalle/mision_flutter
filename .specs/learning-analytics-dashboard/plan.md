# Plan

## Implementación

- Agregar migración v7 con esquema estrella, estado de refresh y triggers de
  auditoría.
- Crear modelos de analytics serializables.
- Extender `FlutterQuestRepository` y `HttpCatalogRepository` con dashboard y
  refresh.
- Crear `AnalyticsService`, `AnalyticsApi` y `SqliteAnalyticsStore`.
- Conectar API en `bin/server.dart` y `createApiHandler`.
- Crear `AnalyticsStore` frontend y registrar provider docente.
- Agregar pestaña `MÉTRICAS` al dashboard docente.
- Actualizar SDD context al finalizar.

## Validación

- Migración crea tablas DW y triggers sin perder datos.
- Refresh idempotente rellena dimensiones/hechos desde datos existentes.
- API rechaza estudiantes y permite docentes.
- UI docente renderiza métricas en desktop/móvil y permite refresh.
- Checks finales:
  - `flutter analyze --no-fatal-infos`
  - `flutter test`
  - `flutter build web`

## Notas De Compatibilidad

- El warehouse queda desacoplado de materias/jornadas por ahora.
- Las tablas DW son reconstruibles; no son fuente de verdad.
- SQLite no tiene stored procedures; el ETL se implementa en Dart con SQL
  portable.

## Estado

- Implementado y verificado.

## Evidencia

- `flutter test`
- `flutter analyze --no-fatal-infos`
- `flutter build web`
