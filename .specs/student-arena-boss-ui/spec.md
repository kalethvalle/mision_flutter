# Especificacion: student-arena-boss-ui

- Estado: Completada
- Rama sugerida: `feature/student-arena-boss-ui`
- Fecha de inicio: 2026-11-02
- Fecha de finalizacion: 2026-11-02

## Objetivo

Redisenar la experiencia del estudiante para separar entrenamiento y parcial en
dos salas claras: Arena de entrenamiento y Camara del jefe final. La experiencia
debe sentirse como una aventura educativa de programacion sin cambiar las reglas
de progreso, autenticacion, autoría ni calificacion existentes.

## Requisitos

- La pantalla inicial del estudiante muestra una navegacion entre Arena de
  entrenamiento y Jefe final.
- La Arena lista mundos, progreso, temas y accion para entrar a misiones.
- La Camara del jefe final lista disponibilidad de parciales, motivos de
  bloqueo, preguntas publicadas, mejor nota, intentos y historial.
- Las misiones mantienen editor, opciones y vista previa, con mejor jerarquia
  visual y copy en sentence case.
- El parcial mantiene seleccion unica/multiple, entrega, resultados, desglose y
  revision, con tratamiento visual diferenciado de jefe final.
- El panel docente queda fuera del rediseno profundo; solo puede heredar tema
  global.
- Un script manual carga preguntas demo publicadas para ambos mundos, de forma
  idempotente y sin crear usuarios ni progreso.

## Criterios de aceptacion

1. La pantalla estudiante inicial muestra `Arena de entrenamiento`.
2. La navegacion permite abrir `Jefe final` sin iniciar una mision.
3. El jefe final muestra mundos bloqueados por progreso o disponibles con
   preguntas publicadas.
4. La arena, mision y parcial se adaptan a movil sin overflow.
5. El script demo inserta cinco preguntas para `world_1` y cuatro para
   `world_2`.
6. Ejecutar el script demo dos veces no duplica preguntas ni opciones.
7. `flutter analyze --no-fatal-infos`, `flutter test` y `flutter build web`
   completan correctamente.

## Fuera de alcance

- Redisenar profundamente el panel docente.
- Automatizar el script demo durante el arranque del servidor.
- Cambiar reglas de desbloqueo, nota minima, snapshots o autorizacion.
- Agregar temporizador, aleatorizacion o limites de intentos.

## Verificacion final

- `flutter analyze --no-fatal-infos`: sin hallazgos.
- `flutter test`: 34 pruebas aprobadas.
- `flutter build web`: compilacion completada.
