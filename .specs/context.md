# Contexto del proyecto

## Propósito

Flutter Quest es una aplicación educativa gamificada para practicar conceptos de
Dart y Flutter mediante mundos y misiones interactivas. Cada misión presenta un
fragmento de código incompleto, varias opciones y una vista previa visual del
resultado.

## Estado técnico actual

- Aplicación Flutter multiplataforma con Dart 3.13.
- Material Design con tema oscuro personalizado.
- Estado reactivo en memoria mediante `provider` y `ChangeNotifier`.
- Dos mundos y nueve misiones definidas localmente:
  - Fundamentos de Dart: cinco misiones.
  - Layouts y Flexbox: cuatro misiones.
- Cada misión presenta primero una guía pedagógica con contexto conceptual,
  aplicación práctica, tres pasos y una pista que no revela la respuesta.
- El mapa resume explícitamente qué se aprende en cada mundo.
- Sin persistencia, autenticación ni servicios de red.

## Arquitectura y flujo de datos

- `lib/main.dart` inicia `FlutterQuestApp`.
- `lib/app.dart` configura `MaterialApp` y expone `GameStore` mediante
  `MultiProvider`.
- `lib/core/models` contiene los contratos de mundos, misiones y opciones.
- `lib/core/store/game_store.dart` administra navegación, selección de
  respuestas, validación, progreso y desbloqueo.
- `lib/core/store/world` contiene el catálogo local de misiones por mundo.
- `lib/features/home/view` presenta el mapa de mundos y la experiencia de cada
  misión.

El flujo principal es: interfaz -> acción del usuario -> `GameStore` ->
`notifyListeners()` -> reconstrucción de la interfaz. El progreso se pierde al
cerrar o reiniciar la aplicación.

## Convención SDD

- La rama base del proyecto es `develop`.
- Cada cambio funcional se desarrolla en una rama `feature/<nombre>`.
- La documentación correspondiente vive en `.specs/<nombre>/`; el prefijo
  `feature/` no forma parte del nombre de la carpeta.
- Los nombres de features usan minúsculas y guiones.
- Cada feature contiene obligatoriamente:
  - `spec.md`: objetivo, requisitos, restricciones y criterios de aceptación.
  - `plan.md`: estrategia, tareas, verificaciones y estado de ejecución.
- El flujo de trabajo es: especificar, planear, implementar, verificar y
  completar.
- Este archivo se actualiza únicamente después de completar y verificar una
  feature. Debe conservar el estado acumulado del producto y enlazar su
  documentación.

## Features completadas

| Feature | Fecha | Implementación |
| --- | --- | --- |
| [`scaffolding`](./scaffolding/spec.md) | 2026-10-27 | Inicialización de Git con `develop`, adopción del contrato SDD, documentación de la línea base de Flutter Quest y reemplazo de la prueba de plantilla por un smoke test real. Consulta el [plan ejecutado](./scaffolding/plan.md). |
| [`mission-guidance`](./mission-guidance/spec.md) | 2026-10-27 | Guía pedagógica previa para las nueve misiones, pistas sin respuesta explícita, tarjetas de aprendizaje para ambos mundos y adaptación responsive del mapa y la experiencia de misión. Consulta el [plan ejecutado](./mission-guidance/plan.md). |

## Deuda técnica conocida

- El analizador reporta 11 avisos informativos: diez por el uso de
  `withOpacity` y uno por un parámetro con guiones bajos redundantes.
- `README.md` conserva el contenido genérico generado por Flutter.
- No existen pruebas específicas para la lógica de progreso de `GameStore` ni
  para el recorrido completo de las misiones.

