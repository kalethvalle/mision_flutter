# Teacher UX Guidance

## Objetivo

Mejorar la presentación UX del panel docente para que crear contenido y
parciales requiera menos esfuerzo cognitivo, y agregar un instructivo práctico
en `docs/` para docentes.

## Contexto

El panel docente ya permite crear estudiantes, mundos, temas, misiones,
preguntas, parciales controlados, resultados y métricas. La funcionalidad está
completa, pero varias pantallas se presentan como listas y formularios sin una
ruta explícita de trabajo. El docente necesita saber qué crear primero, cuándo
publicar y cómo activar parciales sin interpretar detalles técnicos.

## Alcance

- Mejorar la jerarquía visual y el copy del panel docente.
- Agregar orientación de flujo: mundo → tema → misión → pregunta → parcial.
- Reducir trabajo extra con resúmenes visibles y próximos pasos.
- Mantener todas las reglas, modelos, endpoints y permisos existentes.
- Crear `docs/instructivo-docente.md` con pasos para crear mundos, temas,
  misiones, preguntas y parciales.

## No Objetivos

- No cambiar modelo de datos ni migraciones.
- No rediseñar la experiencia estudiantil.
- No implementar materias, jornadas o matrícula.
- No crear onboarding interactivo ni tours guiados.
- No modificar reglas de calificación, anulación ni reportes.

## Requisitos

- La pestaña de estudiantes debe mostrar una orientación breve de operación
  docente.
- La autoría de contenido debe mostrar conteos y una ruta recomendada de
  creación.
- El banco de preguntas debe explicar de forma compacta qué necesita una
  pregunta publicable.
- La vista de parciales debe presentar una secuencia simple: configurar,
  activar, monitorear, cerrar y revisar.
- El instructivo debe ser directo, en español, y usable sin conocer detalles
  internos del código.
- La UI debe conservar contraste, responsive y controles Material existentes.

## Criterios De Aceptación

- Un docente nuevo puede identificar el orden correcto para crear contenido.
- Las pantallas docentes mantienen sus acciones actuales.
- El instructivo documenta:
  - creación de mundos
  - creación de temas
  - creación de misiones
  - creación de preguntas/parciales
  - activación y cierre de una sesión de parcial
  - revisión de resultados y métricas
- `flutter analyze --no-fatal-infos` y `flutter test` deben ejecutarse.

## Impacto UI

- Cambios en vistas docentes bajo `lib/features/auth/view`.
- Nueva documentación en `docs/`.
- No hay impacto en API, base de datos ni contratos Dart.

## Riesgos Y Reversión

- Riesgo: exceso de texto en pantallas densas. Mitigación: usar bloques breves
  y escaneables.
- Riesgo: romper tests por etiquetas de pestañas. Mitigación: conservar textos
  principales usados por pruebas.
- Reversión: los cambios son aditivos de UI/documentación y pueden revertirse
  sin migraciones.
