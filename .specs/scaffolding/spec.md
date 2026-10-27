# Especificación: scaffolding

- Estado: Completada
- Rama: `feature/scaffolding`
- Rama base: `develop`
- Fecha: 2026-10-27

## Objetivo

Establecer la línea base documentada y verificable de Flutter Quest, además del
contrato SDD que se utilizará para desarrollar las siguientes features.

## Comportamiento existente

1. La aplicación inicia en `FlutterQuestApp`, usa un tema oscuro y provee un
   único `GameStore` al árbol de widgets.
2. El mapa presenta dos mundos:
   - Mundo 1, Fundamentos de Dart, desbloqueado inicialmente y compuesto por
     cinco misiones.
   - Mundo 2, Layouts y Flexbox, bloqueado inicialmente y compuesto por cuatro
     misiones.
3. Al entrar a un mundo se muestra su misión actual con enunciado, plantilla de
   código, opciones seleccionables y vista previa.
4. Una respuesta correcta muestra confirmación; una respuesta incorrecta
   muestra un mensaje de error y permite volver a intentar.
5. La navegación permite regresar al mapa y moverse entre las misiones
   disponibles del mundo seleccionado.
6. Acertar la última misión del Mundo 1 desbloquea el Mundo 2 durante la sesión
   actual.
7. La vista de misión distribuye editor y previsualización horizontalmente en
   pantallas mayores a 800 px y verticalmente en pantallas más pequeñas.

## Requisitos del scaffolding

- Inicializar Git con `develop` como rama base y `feature/scaffolding` como
  rama de trabajo.
- Incorporar `.specs/context.md`, este `spec.md` y su `plan.md`.
- Sustituir la prueba de contador generada por Flutter por una prueba del estado
  inicial real de Flutter Quest.
- No modificar las APIs públicas ni el comportamiento productivo existente.
- Conservar como deuda documentada los avisos informativos actuales del
  analizador.

## Criterios de aceptación

- La aplicación puede construirse desde `FlutterQuestApp` sin errores de
  análisis.
- La prueba de widgets confirma el mapa inicial, los dos mundos, un único
  estado `ENTRAR` y un único estado `BLOQUEADO`.
- `flutter analyze --no-fatal-infos` termina sin errores y conserva visibles
  los avisos informativos heredados.
- `flutter test` termina con todas las pruebas aprobadas.
- La rama activa es `feature/scaffolding` y parte del commit base de `develop`.
- Los documentos SDD están enlazados y reflejan el estado final de la feature.

## Fuera de alcance

- Persistencia del progreso.
- Autenticación, servicios remotos o analítica.
- Nuevos mundos o misiones.
- Refactorización de la arquitectura existente.
- Corrección de avisos informativos no bloqueantes.
- Fusión de la feature en `develop`.

## Validación

- `flutter analyze --no-fatal-infos`: aprobado, sin errores y con 11 avisos
  informativos heredados.
- `flutter test`: aprobado, 1 prueba ejecutada.
- Validación completada el 2026-10-27.

