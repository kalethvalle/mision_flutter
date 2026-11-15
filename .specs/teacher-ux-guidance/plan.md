# Plan

## Implementación

- Crear componentes docentes ligeros para encabezado, pasos y métricas de
  orientación.
- Mejorar `TeacherDashboard` con una presentación más clara en la pestaña de
  estudiantes sin cambiar las acciones existentes.
- Mejorar `ContentAuthoringView` y `QuestionBankView` con ruta recomendada,
  resúmenes y copy operativo.
- Mejorar `AssessmentSessionView` con flujo de parcial y resumen de sesiones.
- Crear `docs/instructivo-docente.md`.
- Actualizar `.specs/context.md` al finalizar.

## Archivos Esperados

- `lib/features/auth/view/teacher_dashboard.dart`
- `lib/features/auth/view/authoring_view.dart`
- `lib/features/auth/view/assessment_session_view.dart`
- `docs/instructivo-docente.md`
- `.specs/context.md`

## Trazabilidad

- Ruta docente visible: pasos de operación en estudiantes, contenido,
  preguntas y parciales.
- Menos trabajo extra: conteos y próximos pasos junto a acciones existentes.
- Instructivo: documento operativo en `docs/`.
- Seguridad funcional: sin cambios de backend, base de datos ni permisos.

## Validación

- `dart format` en archivos modificados.
- `flutter analyze --no-fatal-infos`.
- `flutter test`.
- `flutter build web`.

## Estado

- Implementado y verificado.

## Evidencia

- `flutter analyze --no-fatal-infos`
- `flutter test`
- `flutter build web`
