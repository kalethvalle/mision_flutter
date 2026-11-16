# Spec - MongoDB teacher metrics warehouse

## Objetivo

Plantear un escenario de data warehouse NoSQL en MongoDB para las metricas que
el docente consulta en Flutter Quest, sin reemplazar la fuente operativa actual
en SQLite/API ni modificar la logica implementada.

## Contexto

`mision_flutter` ya cuenta con un mini data warehouse local en SQLite para la
pestana docente `METRICAS`. Ese warehouse deriva informacion desde usuarios,
misiones, intentos de entrenamiento, parciales, sesiones, incidentes,
anulaciones y reactivaciones. MongoDB se propone aqui como entregable academico
y como posible capa analitica externa para consultas docentes, snapshots y
respaldo documental.

## Alcance

- Crear contrato de colecciones MongoDB para metricas docentes.
- Justificar por que MongoDB es adecuado para este escenario.
- Explicar que datos se embeben, cuales se referencian y por que.
- Cubrir las consultas docentes principales:
  - resumen KPI general;
  - evolucion por estudiante;
  - rendimiento academico;
  - dificultad por tema;
  - integridad/incidentes/anulaciones;
  - sesiones de parcial por mundo.
- Agregar ejemplos JSON por coleccion.
- Agregar scripts `mongosh` para creacion, validadores, datos iniciales,
  consultas, actualizaciones, agregaciones e indices.
- Agregar programa CRUD de conexion sin contrasenas en codigo.
- Agregar instructivo para armar el entregable de la materia.

## No objetivos

- No migrar la aplicacion Flutter a MongoDB.
- No cambiar `lib/`, modelos, repositorios, API, SQLite ni UI.
- No cambiar la semantica de calificacion, incidentes, anulacion o reactivacion.
- No prometer bloqueo absoluto de navegador; los incidentes siguen siendo
  evidencia auditable y no control infalible.
- No almacenar contrasenas, hashes ni cookies de sesion en MongoDB.

## Requisitos

- R1. El modelo debe respetar el dominio actual: estudiantes, mundos, temas,
  misiones, entrenamiento, parciales, sesiones, eventos de integridad y
  metricas docentes.
- R2. MongoDB debe quedar definido como warehouse derivado/reconstruible; la
  fuente de verdad sigue siendo SQLite/API.
- R3. El diseno debe incluir contrato de colecciones, campos, tipos, indices y
  relaciones.
- R4. El diseno debe justificar embebido vs referencia para cada relacion
  importante.
- R5. Los scripts deben poder ejecutarse en `mongosh`.
- R6. El CRUD debe leer `MONGODB_URI` desde variables de entorno.
- R7. El instructivo debe mapear cada archivo con los entregables solicitados:
  PDF, `datos_iniciales.js`, `consultas.js`, respaldo/export, CRUD y README.

## Criterios de aceptacion

- Existe `.specs/mongodb-teacher-metrics-warehouse/spec.md`.
- Existe `.specs/mongodb-teacher-metrics-warehouse/plan.md`.
- Existe `docs/mongodb-teacher-metrics/documento-diseno.md`.
- Existe `docs/mongodb-teacher-metrics/datos_iniciales.js`.
- Existe `docs/mongodb-teacher-metrics/consultas.js`.
- Existe `docs/mongodb-teacher-metrics/crud_demo.js`.
- Existe `docs/mongodb-teacher-metrics/README.md`.
- No hay cambios en `lib/`, `pubspec.yaml`, tests ni base SQLite operativa.

## Impacto de datos/API/UI

- Datos: propuesta MongoDB derivada para analitica docente.
- API: ninguno en esta fase.
- UI: ninguno en esta fase.

## Seguridad y permisos

- MongoDB debe usar autenticacion.
- Usuario administrador separado del usuario de aplicacion.
- Usuario de aplicacion con `readWrite` solo sobre `flutter_quest_dw`.
- No versionar contrasenas ni URI con password.
- No exportar respuestas correctas en vivo ni secretos de sesiones.

## Riesgos y bloqueos

- Riesgo: duplicacion entre SQLite y MongoDB. Mitigacion: marcar MongoDB como
  derivado y reconstruible con `etl_runs`.
- Riesgo: desalinear metricas respecto a la app. Mitigacion: conservar nombres
  de KPI usados por `AnalyticsDashboard`.
- Riesgo: eventos de integridad interpretados como juicio automatico.
  Mitigacion: documentarlos como senales para revision docente.
- Bloqueo: para ETL real faltaria definir si se cargara desde SQLite directo,
  export JSON o API.

## Reversion

Esta fase solo agrega documentacion y scripts bajo `.specs/` y
`docs/mongodb-teacher-metrics/`; revertir esos archivos no afecta el producto.
