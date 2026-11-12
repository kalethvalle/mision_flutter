# Plan: student-arena-boss-ui

- Estado: Completada
- Especificacion: [spec.md](./spec.md)
- Contexto: [context.md](../context.md)

## Fase 1 - Sistema visual estudiante

- [x] Definir tokens de color y superficie para la experiencia estudiante.
- [x] Aplicar tema global sin redisenar el panel docente en profundidad.
- [x] Reducir mayusculas decorativas en acciones y estados estudiantiles.

## Fase 2 - Arena y jefe final

- [x] Separar la pantalla estudiante en Arena de entrenamiento y Jefe final.
- [x] Mover disponibilidad, accion e historial de parciales a la sala de jefe.
- [x] Mantener el flujo de misiones existente desde la Arena.

## Fase 3 - Misiones y parcial

- [x] Mejorar jerarquia de guia, codigo, opciones y preview.
- [x] Dar tratamiento visual diferenciado al parcial y sus resultados.
- [x] Mantener reglas de seleccion, entrega y revision sin cambios funcionales.

## Fase 4 - Datos demo

- [x] Crear script manual `bin/seed_demo_assessments.dart`.
- [x] Insertar preguntas publicadas idempotentes para ambos mundos.
- [x] Cubrir idempotencia y conteos con prueba automatizada.

## Fase 5 - Verificacion

- [x] Actualizar widget tests de arena, jefe final, movil e historial.
- [x] Ejecutar `flutter analyze --no-fatal-infos`.
- [x] Ejecutar `flutter test`.
- [x] Ejecutar `flutter build web`.
- [x] Actualizar estado final de spec, plan y contexto si todo pasa.

## Resultado

Implementacion completada y verificada el 2026-11-02. La experiencia del
estudiante separa entrenamiento y jefe final, las misiones y parciales usan una
jerarquia visual consistente, y el script demo carga preguntas publicadas para
ambos mundos de forma idempotente.
