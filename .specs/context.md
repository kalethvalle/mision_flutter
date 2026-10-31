# Contexto del proyecto

## Propósito

Flutter Quest es una aplicación educativa gamificada para practicar conceptos de
Dart y Flutter mediante mundos y misiones interactivas. Cada misión presenta un
fragmento de código incompleto, varias opciones y una vista previa visual del
resultado.

## Estado técnico actual

- Aplicación Flutter Web con cliente y servidor Dart local, usando Dart 3.13.
- Material Design con tema oscuro personalizado.
- Estado reactivo de sesión y juego mediante `provider` y `ChangeNotifier`.
- Catálogo SQLite con dos mundos, nueve temas y nueve misiones:
  - Fundamentos de Dart: cinco misiones.
  - Layouts y Flexbox: cuatro misiones.
- Cada misión presenta primero una guía pedagógica con contexto conceptual,
  aplicación práctica, tres pasos y una pista que no revela la respuesta.
- El mapa resume explícitamente qué se aprende en cada mundo.
- La API local entrega el catálogo y comprueba respuestas sin exponer la
  solución en los endpoints de lectura.
- Cuentas locales `teacher`/`student`, claves con Argon2id y sesiones opacas
  mediante cookie `HttpOnly` con vencimiento de 12 horas.
- Intentos, uso de pistas, progreso y desbloqueos secuenciales persistidos por
  estudiante en SQLite.

## Arquitectura y flujo de datos

- `lib/main.dart` inicia `FlutterQuestApp` con el repositorio HTTP.
- `lib/app.dart` configura `MaterialApp` y expone `SessionStore`; al autenticar
  un estudiante se crea su `GameStore` aislado.
- `lib/core/models` contiene contratos Dart puros y serializables.
- `lib/core/repositories` define los puertos de catálogo, identidad, progreso y
  respuesta, además del adaptador HTTP usado por Flutter Web.
- `lib/core/store` administra sesión, carga asíncrona, navegación, selección,
  feedback y la vista del progreso persistido.
- `lib/application` contiene casos de uso de catálogo, identidad y progreso.
- `lib/server` contiene API Shelf, migraciones, semilla y repositorios SQLite.
- `bin/server.dart` sirve `build/web` y `/api/v1` desde el mismo origen.
- `lib/features/home/view` presenta el mapa de mundos y la experiencia de cada
  misión.

El flujo principal es: interfaz → stores → repositorio HTTP → API → casos de uso
→ repositorios SQLite. La API resuelve la identidad desde la sesión, aplica el
rol y vuelve a calcular bloqueos antes de guardar cada intento. La respuesta
actualiza el store y `notifyListeners()` reconstruye la interfaz.

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
| [`catalog-foundation`](./catalog-foundation/spec.md) | 2026-10-27 | Catálogo persistente con migración y semilla idempotente, nueve temas, API local, comprobación segura de respuestas, adaptadores SQLite/HTTP y entrega de Flutter Web desde el mismo origen. Consulta el [plan ejecutado](./catalog-foundation/plan.md). |
| [`identity-progress`](./identity-progress/spec.md) | 2026-10-30 | Bootstrap docente, cuentas estudiantiles, claves Argon2id, sesiones locales, autorización por rol e intentos y progreso secuencial persistidos y aislados por estudiante. Consulta el [plan ejecutado](./identity-progress/plan.md). |

## Deuda técnica conocida

- No hay cambio o recuperación de clave ni edición o desactivación de cuentas.
- Todavía no existe editor de contenido, banco de preguntas, parciales ni
  informes docentes de desempeño.
- Android aún no tiene adaptador SQLite nativo ni validación en esta fase.

