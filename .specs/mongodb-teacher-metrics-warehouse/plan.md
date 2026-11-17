# Plan - MongoDB teacher metrics warehouse

## Pasos

1. Leer `.specs/context.md`, `learning-analytics-dashboard`, parciales
   controlados, modelos de analytics y repositorios SQLite.
2. Definir MongoDB como warehouse externo derivado, no fuente operativa.
3. Modelar colecciones para consultas docentes:
   - `students`
   - `learning_catalog`
   - `training_attempts`
   - `assessment_attempts`
   - `integrity_events`
   - `teacher_metric_snapshots`
   - `etl_runs`
4. Documentar contrato, decisiones de embebido/referencia, indices y seguridad.
5. Crear script de datos iniciales con validadores e indices.
6. Crear script de consultas con agregaciones y actualizaciones.
7. Crear CRUD de demostracion con `MONGODB_URI`.
8. Crear README/instructivo del entregable.
9. Actualizar `.specs/context.md` con la decision y validacion.

## Archivos a cambiar

- `.specs/context.md`
- `.specs/mongodb-teacher-metrics-warehouse/spec.md`
- `.specs/mongodb-teacher-metrics-warehouse/plan.md`
- `docs/mongodb-teacher-metrics/README.md`
- `docs/mongodb-teacher-metrics/documento-diseno.md`
- `docs/mongodb-teacher-metrics/datos_iniciales.js`
- `docs/mongodb-teacher-metrics/consultas.js`
- `docs/mongodb-teacher-metrics/crud_demo.js`

## Trazabilidad

- R1 -> secciones de dominio y colecciones.
- R2 -> objetivo, no objetivos, seguridad y `etl_runs`.
- R3 -> contrato de colecciones e indices.
- R4 -> tabla de embebido/referencia.
- R5 -> `datos_iniciales.js` y `consultas.js`.
- R6 -> `crud_demo.js`.
- R7 -> `README.md`.

## Validacion

- Revision estatica de archivos generados.
- `node --check docs/mongodb-teacher-metrics/crud_demo.js`.
- No se ejecuta Flutter porque no se toca codigo de aplicacion.
- No se ejecuta `mongosh` si no esta instalado localmente.

## Compatibilidad

- SQLite/API continua como fuente de verdad.
- MongoDB puede cargarse por export de SQLite, endpoint docente futuro o script
  ETL externo.
- Los identificadores se mantienen como `string` para mapear con tablas
  existentes (`users`, `worlds`, `topics`, `missions`, attempts y sessions).

## Estado

- Completado como fase documental y scripts de entregable.

## Evidencia

- Revision estatica de archivos generados.
- `node --check docs/mongodb-teacher-metrics/crud_demo.js`.
- No se ejecuto `mongosh` porque no esta disponible en el entorno.
- No se ejecutaron pruebas Flutter porque no hubo cambios en codigo de
  aplicacion.
