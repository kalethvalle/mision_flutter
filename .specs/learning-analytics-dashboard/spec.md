# Learning Analytics Data Warehouse Dashboard

## Objetivo

Crear un mini data warehouse local en SQLite y un dashboard docente de métricas
para interpretar la evolución y el rendimiento académico de estudiantes usando
los datos ya generados por Flutter Quest.

## Contexto

La aplicación ya registra entrenamiento, progreso de misiones, parciales,
eventos de integridad, anulaciones y reportes docentes. Hoy esos datos existen
como registros operativos, pero no hay una vista agregada que permita al docente
responder preguntas de mejora, desempeño e integridad.

## Alcance

- Data warehouse derivado y reconstruible desde las tablas operativas actuales.
- Dashboard docente independiente de `RESULTADOS`.
- Métricas globales por estudiante, mundo y tema.
- Refresh manual vía endpoint docente.
- Auditoría mediante triggers SQLite sobre tablas relevantes.
- Documentar como épica futura materias, jornadas e inscripción.

## No Objetivos

- No implementar materias, jornadas, grupos ni matrícula en esta fase.
- No cambiar el flujo estudiantil ni exigir contexto académico activo.
- No reemplazar el reporte detallado existente.
- No agregar sincronización externa ni exportación.

## Requisitos

- Crear tablas estrella materializadas para dimensiones y hechos.
- Crear `analytics_audit_log` y triggers sobre usuarios, intentos de
  entrenamiento, progreso, parciales y eventos de parcial.
- Implementar refresh idempotente del data warehouse.
- Exponer `GET /api/v1/analytics/dashboard` y
  `POST /api/v1/analytics/refresh` solo para docentes.
- Mostrar pestaña docente `MÉTRICAS` con KPIs, evolución, rendimiento,
  dificultad por tema e integridad.
- El dashboard debe soportar estado vacío, error, cargando y refresh manual.

## Impacto De Datos/API/UI

- Nueva migración SQLite con tablas `dw_*`, `dw_refresh_state` y
  `analytics_audit_log`.
- Nuevos modelos Dart `AnalyticsDashboard`, `AnalyticsKpiSummary`,
  `StudentEvolutionMetric`, `AcademicPerformanceMetric`,
  `TopicDifficultyMetric` e `IntegrityMetric`.
- Nuevo servicio/repositorio `AnalyticsService` y `SqliteAnalyticsStore`.
- Nueva API `AnalyticsApi`.
- Nueva pestaña docente `MÉTRICAS`.

## Seguridad Y Permisos

- Solo docentes pueden consultar o refrescar analytics.
- El dashboard no expone claves, hashes, respuestas correctas en vivo ni datos
  fuera de los registros académicos existentes.

## Riesgos Y Reversión

- Las tablas DW son derivadas: se pueden borrar y reconstruir.
- Si una métrica falla, `RESULTADOS` sigue funcionando como fuente operativa.
- La migración debe ser aditiva para no perder intentos ni sesiones existentes.

## Épica Futura

- `subjects`: materias gestionadas por docente.
- `subject_sections`: materia + jornada (`diurna`, `nocturna`, `sabatina`).
- `section_enrollments`: estudiantes inscritos por sección.
- Contexto activo estudiante para atribuir intentos nuevos a una
  materia-jornada.
