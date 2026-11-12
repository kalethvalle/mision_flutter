# Plan

## Implementación

- Crear migración SQLite para configuraciones por mundo, sesiones, borradores,
  eventos, deadline y estado `annulled` en intentos.
- Extender modelos, repositorios, servicios y API de parciales con sesiones,
  incidentes, borradores, reactivación, SSE y reporte detallado.
- Añadir store docente para sesiones y ampliar `ReportStore` con detalle.
- Añadir pestaña docente `PARCIALES`.
- Reforzar vista estudiantil del jefe final con pantalla completa, watermark,
  registro de incidentes y guardado incremental.
- Mantener snapshots, calificación 80, intentos repetibles y reportes previos.

## Archivos Principales

- `lib/server/database/catalog_database.dart`
- `lib/server/repositories/sqlite_assessment_store.dart`
- `lib/server/api/assessment_api.dart`
- `lib/core/models/assessment_model.dart`
- `lib/core/store/assessment_store.dart`
- `lib/features/auth/view/assessment_session_view.dart`
- `lib/features/home/view/assessment_view.dart`

## Validación

- Actualizar tests existentes para abrir sesión antes de intentos exitosos.
- Agregar cobertura de migración, bloqueo sin sesión, incidentes/anulación,
  reactivación y reporte detallado cuando el primer análisis compile.
- Ejecutar:
  - `flutter analyze --no-fatal-infos`
  - `flutter test`
  - `flutter build web`

## Estado

- Implementado y verificado.
- `flutter analyze --no-fatal-infos`: sin issues.
- `flutter test`: 34 tests aprobados.
- `flutter build web`: build generado correctamente.
