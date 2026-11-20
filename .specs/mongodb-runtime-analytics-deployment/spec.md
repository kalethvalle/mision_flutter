# Spec - MongoDB runtime analytics deployment

## Objetivo

Habilitar MongoDB como almacen derivado para metricas y analitica docente,
manteniendo SQLite como fuente operacional de verdad y conservando intactos los
flujos existentes de estudiantes, docentes, parciales, sesiones y progreso.

## Contexto

El dashboard `METRICAS` ya funciona con un data warehouse reconstruible en
SQLite mediante `SqliteAnalyticsStore`. Existe ademas un entregable documental
que modela MongoDB como warehouse para metricas docentes, pero no participa en
runtime ni en Docker.

## Alcance

- Agregar seleccion de backend analitico por configuracion.
- Mantener SQLite como backend por defecto.
- Agregar MongoDB como snapshot/warehouse derivado para la misma respuesta
  `AnalyticsDashboard`.
- Agregar Docker para ejecutar la aplicacion en modo SQLite y en modo
  SQLite + MongoDB analitico.
- Documentar MER SQL y modelo documental MongoDB para incorporarlos al RFC.
- Registrar la implementacion en `.specs/context.md` al finalizar.

## No objetivos

- No migrar autenticacion, sesiones, parciales, calificaciones ni progreso a
  MongoDB.
- No cambiar la UI ni el contrato HTTP del dashboard docente.
- No almacenar passwords, hashes, sales, cookies ni tokens en MongoDB.
- No implementar refresh automatico ni jobs en background en esta fase.

## Requisitos

- R1. `GET /api/v1/analytics/dashboard` y
  `POST /api/v1/analytics/refresh` deben conservar el mismo JSON.
- R2. `ANALYTICS_STORE=sqlite` o ausencia de configuracion debe usar el store
  actual sin depender de MongoDB.
- R3. `ANALYTICS_STORE=mongo` debe leer/publicar el dashboard desde MongoDB,
  reconstruyendo datos desde SQLite al refrescar.
- R4. Un fallo de MongoDB no debe modificar ni corromper SQLite.
- R5. Si falla un refresh MongoDB, el ultimo snapshot publicado debe seguir
  disponible.
- R6. Docker debe incluir un compose SQLite y otro compose SQLite + MongoDB.
- R7. La documentacion debe incluir MER SQL, modelo documental MongoDB,
  variables de entorno y comandos de despliegue.

## Impacto de datos, API y despliegue

- API publica: sin cambios.
- SQLite: sin migraciones nuevas obligatorias.
- MongoDB: colecciones derivadas `students`, `learning_catalog`,
  `training_attempts`, `assessment_attempts`, `integrity_events`,
  `teacher_metric_snapshots` y `etl_runs`.
- Docker: nuevos archivos compose y variables de entorno de analitica.

## Seguridad y permisos

- La autorizacion docente sigue en `AnalyticsService`.
- MongoDB solo contiene datos academicos derivados necesarios para metricas.
- Las credenciales se documentan con placeholders y se inyectan por entorno.

## Criterios de aceptacion

- La aplicacion arranca y sirve metricas con SQLite sin configurar MongoDB.
- La aplicacion arranca con MongoDB configurado y publica snapshots al refrescar.
- El dashboard docente conserva contrato y permisos.
- Los compose validan su configuracion.
- Las pruebas unitarias cubren seleccion de backend y compatibilidad del
  comportamiento por defecto.
- La documentacion queda lista para enlazarse desde el RFC.

## Riesgos y reversibilidad

- Riesgo: divergencia entre SQLite y MongoDB. Mitigacion: MongoDB se reconstruye
  desde SQLite y el snapshot solo se publica tras un refresh completo.
- Riesgo: dependencia externa no disponible. Mitigacion: SQLite sigue como
  backend por defecto y fallback operativo.
- Reversion: definir `ANALYTICS_STORE=sqlite` o revertir los archivos nuevos
  deja el flujo actual sin MongoDB.
