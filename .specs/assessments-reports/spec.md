# Especificación: assessments-reports

- Estado: Completada
- Rama: `feature/assessments-reports`
- Base: `develop` (`45e1336`)
- Fecha de inicio: 2026-10-30
- Fecha de finalización: 2026-10-30
- Historias relacionadas: HU-09, HU-10, HU-11 y HU-12

## Objetivo

Completar el ciclo formativo de cada mundo con un parcial («jefe final»),
calificación y retroalimentación posterior, historial de intentos repetibles e
informes docentes de entrenamiento y parciales. Toda evaluación se resuelve y
califica en el servidor usando contenido versionado.

## Disponibilidad e inicio

- Un parcial se habilita cuando el estudiante completó todas las misiones
  publicadas del mundo y existe al menos una pregunta publicada de sus temas.
- Si faltan misiones o preguntas, la interfaz muestra el motivo y el servidor
  rechaza el inicio directo.
- Al iniciar se copian en el intento todas las preguntas publicadas del mundo,
  sus opciones, solución, explicación, tema y versión vigente.
- Solo existe un intento abierto por estudiante y mundo; iniciar de nuevo lo
  reanuda. Después de entregarlo se puede crear otro sin límite.
- El intento abierto nunca entrega solución ni explicación al cliente.

## Respuestas y calificación

- Selección única admite como máximo una opción; selección múltiple admite
  varias. Una pregunta vacía es incorrecta.
- Una respuesta es correcta únicamente si el conjunto elegido coincide
  exactamente con el conjunto correcto fijado en el intento.
- La nota entera es `round(100 × aciertos / preguntas)` y se aprueba con nota
  mayor o igual a 80.
- La entrega es atómica y definitiva. Repetir una petición de entrega devuelve
  conflicto y no modifica respuestas ni nota.
- Después de entregar se muestran nota, aprobación, resultado por tema,
  selección, solución y explicación de cada pregunta.

## Historial e informes

- El estudiante consulta exclusivamente sus intentos, en orden descendente,
  con mundo, fecha, nota y aprobación.
- El docente consulta intentos de entrenamiento y parciales de todos los
  estudiantes, diferenciados y ordenados por fecha.
- El informe se puede filtrar por estudiante, mundo y tema. Los filtros se
  aplican en el servidor y nunca amplían permisos del estudiante.
- Editar preguntas después de entregar no cambia enunciados, soluciones,
  explicaciones, notas ni versiones históricas.

## API

- `GET /api/v1/assessments`: disponibilidad, intento abierto e historial propio.
- `POST /api/v1/worlds/:worldId/assessments`: inicia o reanuda un intento.
- `GET /api/v1/assessments/:id`: recupera un intento abierto sin soluciones.
- `POST /api/v1/assessments/:id/submit`: entrega respuestas y devuelve resultado.
- `GET /api/v1/assessments/:id/result`: recupera un resultado propio cerrado.
- `GET /api/v1/reports`: informe docente con filtros opcionales.

## Persistencia

La migración 4 añadirá intentos, preguntas fijadas, opciones fijadas y
respuestas seleccionadas. Las claves foráneas conservan usuario, mundo,
pregunta original y tema, pero el resultado se reconstruye siempre desde las
copias del intento para mantener el historial aunque cambie el banco.

## Interfaz

- Cada tarjeta de mundo muestra el estado del jefe final y su acción disponible.
- La vista de parcial permite responder preguntas single/multiple y entregar.
- La vista de resultado muestra nota, aprobación, desglose y explicaciones.
- El mapa ofrece historial y repetición de parciales.
- El panel docente añade una pestaña de resultados con filtros e intentos
  diferenciados.
- Todo debe funcionar en móvil y escritorio sin overflow.

## Criterios de aceptación

1. Mundo incompleto o sin preguntas no permite iniciar y explica el bloqueo.
2. Un intento contiene solo preguntas publicadas de temas del mundo.
3. Un intento abierto no filtra solución ni explicación.
4. Selección múltiple exige coincidencia exacta; vacío cuenta como error.
5. Nota 80 aprueba y una nota menor no aprueba.
6. Un intento solo se entrega una vez y queda inmutable.
7. Editar una pregunta no altera un resultado cerrado.
8. El estudiante ve únicamente su historial y puede repetir sin sobrescribirlo.
9. El docente filtra entrenamiento y parciales por estudiante, mundo y tema.
10. Un estudiante recibe `403` al solicitar el informe docente.
11. Análisis, pruebas, build web y smoke local finalizan correctamente.

## Fuera de alcance

- Temporizador, aleatorización, límite de intentos o banco adaptativo.
- Ponderaciones distintas por pregunta o calificaciones decimales.
- Exportación de informes, gráficos avanzados o sincronización remota.
- Notificaciones, recuperación de clave y Android nativo.
- Fusionar o publicar automáticamente la rama.

## Verificación final

- `flutter analyze --no-fatal-infos`: sin hallazgos.
- `flutter test`: 33 pruebas aprobadas.
- `flutter build web`: compilación completada.
- Smoke local: web, cinco misiones, pregunta publicada, parcial, calificación,
  resultado e informe después de reiniciar servidor/SQLite aprobados.
