# Plan

## Implementación

- Agregar migración v6 con `missions.selection_type`,
  `assessment_* .annulled_score` y `training_attempt_options`.
- Extender modelos, repositorios HTTP/API y servicios para selección múltiple
  en entrenamiento manteniendo compatibilidad con `optionId`.
- Ajustar calificación de entrenamiento a conjunto exacto.
- Ajustar configuración de parciales para nota por anulación y congelarla en
  la sesión.
- Guardar nota por anulación al anular, mostrarla en resultado y reportes.
- Rediseñar UI de Arena/Parcial con radio/checkbox y pista contrastada.
- Mostrar incidentes como lista estructurada en monitor y detalle.

## Validación

- `flutter analyze --no-fatal-infos`
- `flutter test`
- `flutter build web`

## Estado

- Implementación completada y verificada.

## Evidencia

- `flutter analyze --no-fatal-infos`: sin errores; quedan avisos informativos
  por la API nueva de `RadioListTile`.
- `flutter test`: 36 tests aprobados.
- `flutter build web`: compilación web exitosa.
