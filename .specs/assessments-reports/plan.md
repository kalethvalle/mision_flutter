# Plan: assessments-reports

- Estado: Completada
- Rama: `feature/assessments-reports`
- Especificación: [spec.md](./spec.md)
- Historias: [stories-users.md](../../docs/stories-users.md)
- Contexto: [context.md](../context.md)

## Fase 0 — Preparación

- [x] Revisar HU-09 a HU-12 y la secuencia SDD.
- [x] Confirmar `develop` actualizado y crear la rama.
- [x] Ejecutar análisis y pruebas de línea base.
- [x] Preservar `devtools_options.yaml` sin versionar.

## Fase 1 — Dominio y persistencia

- [x] Definir modelos, contratos y reglas de parciales e informes.
- [x] Crear migración 4 con snapshots y respuestas.
- [x] Implementar disponibilidad e inicio/reanudación.
- [x] Implementar entrega atómica, nota y desglose.
- [x] Implementar historial inmutable y repetición.
- [x] Implementar informe filtrable de entrenamiento y parciales.

## Fase 2 — API y cliente

- [x] Crear endpoints estudiantiles sin filtrar soluciones.
- [x] Crear endpoint docente de informes.
- [x] Aplicar propiedad de intentos y autorización por rol.
- [x] Ampliar el repositorio HTTP.

## Fase 3 — Flutter Web

- [x] Mostrar disponibilidad del jefe final en el mapa.
- [x] Crear vista de preguntas single/multiple.
- [x] Crear resultado, desglose, explicaciones e historial.
- [x] Permitir repetir parciales sin reemplazar intentos.
- [x] Añadir pestaña docente de resultados y filtros.
- [x] Verificar presentación móvil y escritorio.

## Fase 4 — Pruebas y cierre

- [x] Probar bloqueo por progreso y ausencia de preguntas.
- [x] Probar snapshot, privacidad y edición posterior.
- [x] Probar selección exacta, vacíos, nota 80 y entrega única.
- [x] Probar aislamiento, repetición e historial cronológico.
- [x] Probar autorización y filtros docentes.
- [x] Probar widgets móvil/escritorio.
- [x] Ejecutar análisis, pruebas y build web.
- [x] Ejecutar smoke Web/API/SQLite con reinicio.
- [x] Actualizar README, spec, plan y finalmente `context.md`.
- [x] Crear el commit `feat: add assessments and reports`.
- [x] Mantener la rama sin merge ni push.

## Riesgos

- **Soluciones expuestas:** DTO abierto omite solución y explicación.
- **Historia mutable:** snapshots completos dentro de cada intento.
- **Entrega duplicada:** transacción `BEGIN IMMEDIATE` y estado cerrado.
- **Acceso cruzado:** usuario del intento se resuelve desde la sesión.

## Resultado

Implementación completada y verificada el 2026-10-30. Los estudiantes presentan
parciales versionados, reciben calificación y retroalimentación, conservan y
repiten intentos; los docentes consultan entrenamiento y parciales con filtros.
