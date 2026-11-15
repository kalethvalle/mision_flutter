# Assessment Session Refinements

## Objetivo

Mejorar Arena de entrenamiento y Parciales controlados con contraste legible,
controles de selección según tipo, nota configurable por anulación e incidentes
docentes detallados.

## Alcance

- La pista de Arena debe verse con contraste alto.
- Las misiones de entrenamiento tendrán `selectionType` (`single`/`multiple`).
- Arena usa radio buttons para selección única y checkboxes para selección
  múltiple.
- Parciales usan radio buttons o checkboxes según el tipo de pregunta.
- El docente configura una nota por anulación por mundo/sesión.
- Los intentos anulados muestran esa nota al estudiante y al docente.
- Docentes ven cada incidente en el monitor de `PARCIALES` y en el detalle de
  `RESULTADOS`.

## No Objetivos

- No cambiar previews de código para combinar múltiples snippets.
- No exponer respuestas en vivo antes de la entrega.
- No cambiar la regla de aprobación de parciales entregados.

## Requisitos

- Bases existentes migran sin perder intentos ni sesiones.
- Misiones existentes se consideran selección única.
- API de entrenamiento acepta `optionId` legado y `optionIds` nuevo.
- La selección múltiple se califica por conjunto exacto.
- Una anulación estricta guarda `score = annulledScore`, `passed = false`,
  `correctAnswers = 0` y motivo de anulación.

## Validación

- Migración v5 a v6.
- Tests backend de selección única/múltiple.
- Tests de anulación con nota configurada.
- Tests widget para radio/checkbox e incidentes visibles.
