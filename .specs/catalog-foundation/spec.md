# Especificación: catalog-foundation

- Estado: Completada
- Rama: `feature/catalog-foundation`
- Rama base: `develop`
- Fecha de inicio: 2026-10-27
- Fecha de finalización: 2026-10-27
- Historias relacionadas: HU-01, HU-02, HU-03 y HU-04

## Objetivo

Crear la base de dominio y persistencia del catálogo de Flutter Quest. Los dos
mundos y las nueve misiones actuales dejarán de estar acoplados a `GameStore` y
se cargarán de forma idempotente en SQLite. Flutter Web consultará el catálogo y
validará respuestas mediante una API HTTP servida desde el mismo proceso Dart.

La experiencia visible de HU-01 a HU-04 debe conservarse. Esta fase prepara los
contratos de intentos y progreso, pero no declara completa la persistencia de
HU-04: asociar intentos a una cuenta corresponde a identidad y progreso.

## Alcance funcional

### HU-01 — Explorar mundos

- Consultar mundos publicados, ordenados y con sus temas desde el repositorio.
- Mostrar inicialmente el Mundo 1 disponible y el Mundo 2 bloqueado.
- Mantener temporalmente en memoria el desbloqueo actual; su persistencia y la
  nueva regla de avance se implementarán con HU-05 y HU-06.
- Distinguir el estado editorial de un mundo de su disponibilidad para jugar.

### HU-02 — Consultar la guía

- Obtener del catálogo el objetivo, dos párrafos, tres pasos y la pista de cada
  misión publicada.
- Conservar el orden, contenido y límites visuales de la guía actual.
- Cambiar toda la guía al navegar entre misiones sin mezclar datos anteriores.

### HU-03 — Resolver una misión

- Obtener plantilla, marcador, opciones y tipo de vista previa por repositorio.
- Mantener selección única y vista previa inmediata en el navegador.
- Resolver `previewType` mediante un registro cerrado de widgets implementados;
  no almacenar widgets ni ejecutar código recibido como texto.
- Impedir el envío de una comprobación sin una opción seleccionada.

### HU-04 — Recibir retroalimentación

- Enviar al servidor el identificador de misión y de la opción seleccionada.
- Validar en el servidor que misión y opción existan y estén publicadas.
- Retornar acierto o error sin exponer la respuesta correcta en el catálogo.
- Conservar la retroalimentación y la posibilidad de reintentar.
- No persistir todavía intentos anónimos: el historial asociado a cuentas se
  implementará en la fase de identidad y progreso.

## Modelo de dominio

Los modelos de dominio serán Dart puro y no importarán Flutter, HTTP ni SQLite.

- `World`: identificador estable, título, descripción, orden, estado editorial,
  clave de icono y color hexadecimal.
- `Topic`: identificador estable, mundo, título, descripción, orden y estado.
- `Mission`: identificador estable, mundo, tema, título, objetivo, categoría,
  tipo de vista previa, plantilla, marcador, pista, orden y estado editorial.
- `MissionOption`: identificador estable, misión, etiqueta, fragmento y orden.
- `AnswerCheckResult`: identificador de misión, acierto y mensaje de resultado.

El catálogo inicial tendrá nueve temas, uno por habilidad entrenada: tipos
numéricos, `final`, funciones flecha, listas tipadas, null safety, `Row`,
`Column`, padding y `Stack`/`Positioned`.

## Contratos y casos de uso

- `CatalogRepository`: listar mundos y temas publicados, listar misiones por
  mundo y consultar una misión.
- `MissionAnswerRepository`: comprobar una opción sin revelar la solución al
  consumidor público.
- `InitializeCatalog`: ejecutar migraciones y carga inicial idempotente.
- `ListWorlds`, `ListWorldMissions` y `GetMission`: consultar el catálogo.
- `CheckMissionAnswer`: aplicar las reglas de validación de HU-04.

Las interfaces pertenecen al dominio o a la aplicación. SQLite y HTTP son
adaptadores sustituibles; la presentación no conoce tablas ni sentencias SQL.

## Persistencia SQLite

La primera migración creará como mínimo:

- `schema_migrations`: versión y fecha aplicada.
- `worlds`: datos editoriales, presentación declarativa, orden y estado.
- `topics`: temas asociados a un mundo.
- `missions`: contenido principal, tema, `preview_type`, orden y estado.
- `mission_context_paragraphs`: dos párrafos ordenados por misión.
- `mission_instructions`: tres pasos ordenados por misión.
- `mission_options`: opciones ordenadas y marca de solución solo del servidor.

Se activarán claves foráneas. Migraciones y semilla se ejecutarán en
transacciones. Los identificadores actuales serán deterministas y la segunda
ejecución no insertará mundos, temas, misiones ni opciones duplicados.

La base predeterminada será `data/flutter_quest.sqlite3`. El servidor creará el
directorio cuando sea necesario y `data/` quedará excluido de Git.

## API HTTP local

La API usará JSON bajo `/api/v1`:

| Método y ruta | Resultado |
| --- | --- |
| `GET /api/v1/health` | Estado del servidor y acceso a la base. |
| `GET /api/v1/worlds` | Mundos publicados, ordenados y con sus temas. |
| `GET /api/v1/worlds/:worldId/missions` | Resumen ordenado de misiones publicadas. |
| `GET /api/v1/missions/:missionId` | Guía, ejercicio y opciones de una misión. |
| `POST /api/v1/missions/:missionId/check` | Resultado para `{ "optionId": "..." }`. |

Los DTO públicos nunca incluirán `isCorrect`, `correctOptionId` ni equivalentes.
Los errores usarán un cuerpo estable con `code` y `message`, y códigos HTTP
adecuados para entrada inválida, recurso inexistente y fallo interno.

El servidor escuchará por defecto en `127.0.0.1`, servirá también `build/web` y
resolverá las rutas de Flutter Web con `index.html`. Web y API compartirán
origen, por lo que esta fase no necesita CORS.

## Adaptación de Flutter Web

- Sustituir el catálogo importado directamente por un repositorio HTTP.
- Hacer explícitos los estados de carga, contenido vacío y error de conexión.
- Mantener `GameStore` como coordinador de presentación mientras se separan las
  responsabilidades de catálogo, selección y retroalimentación.
- Inyectar el cliente/repo para permitir pruebas sin un servidor real.
- Mapear `iconKey` y `previewType` con registros locales exhaustivos y mostrar
  un error controlado si el servidor entrega una clave no admitida.
- Conservar el diseño responsive y el orden guía → código → opciones → acción.

## Requisitos no funcionales

- Usar únicamente consultas parametrizadas para valores variables.
- Cerrar la conexión SQLite al detener el servidor.
- No ocultar fallos de apertura o escritura de la base con datos simulados.
- Mantener separados los imports exclusivos de servidor para que Flutter Web
  no compile `dart:io` ni el adaptador SQLite.
- Registrar inicio, migración y errores sin imprimir soluciones del catálogo.

## Criterios de aceptación

1. Un primer arranque crea la base, aplica la migración y carga exactamente dos
   mundos, nueve temas y nueve misiones con sus guías y opciones.
2. Dos inicializaciones consecutivas conservan las mismas cantidades e IDs.
3. La API lista solo contenido publicado y respeta el orden configurado.
4. Ninguna respuesta de lectura revela qué opción es correcta.
5. Una comprobación válida devuelve éxito o error; IDs ajenos a la misión y
   cuerpos inválidos se rechazan sin modificar datos.
6. El mapa y las nueve misiones conservan su contenido y comportamiento visible
   al consumir la API, tanto en móvil como en escritorio.
7. La caída o indisponibilidad del servidor produce un estado de error visible.
8. El servidor entrega `build/web` y la API desde el mismo origen local.
9. Las pruebas de dominio, SQLite, API y widgets pasan; el análisis no introduce
   errores ni avisos nuevos y `flutter build web` finaliza correctamente.

## Trazabilidad de historias

| Historia | Entrega en esta feature | Estado esperado al cierre |
| --- | --- | --- |
| HU-01 | Catálogo y temas por repositorio; disponibilidad actual en memoria. | Migrada, pendiente de progreso persistido. |
| HU-02 | Guía completa obtenida desde SQLite/API. | Migrada. |
| HU-03 | Ejercicio, opciones y registro de vistas previas. | Migrada. |
| HU-04 | Comprobación segura en servidor y feedback; sin historial por cuenta. | Migrada parcialmente; persistencia en fase 2. |

## Restricciones

- No cambiar respuestas, textos pedagógicos ni apariencia salvo estados de
  carga/error necesarios para la consulta asíncrona.
- No implementar autenticación, autorización, progreso persistente ni la nueva
  regla de desbloqueo de HU-05.
- No implementar editor docente, preguntas, parciales ni informes.
- No ejecutar código Dart arbitrario ni construir widgets desde contenido.
- No declarar Android verificado en esta fase.
- No actualizar `.specs/context.md` hasta completar y verificar la feature.

## Fuera de alcance

- HU-05 a HU-12.
- Persistencia o migración de intentos anónimos.
- Sincronización remota, despliegue público o acceso desde otros equipos.
- Fusión o publicación automática de la rama.

## Referencias técnicas

- [`shelf`](https://pub.dev/packages/shelf) y
  [`shelf_router`](https://pub.dev/packages/shelf_router) para la API.
- [`shelf_static`](https://pub.dev/documentation/shelf_static/latest/shelf_static/)
  para servir Flutter Web.
- [`http`](https://pub.dev/packages/http) para el adaptador cliente inyectable.
- [`sqlite3`](https://pub.dev/documentation/sqlite3/latest/) para la base local.

## Validación

- Catálogo idempotente verificado con 2 mundos, 9 temas y 9 misiones.
- Las lecturas HTTP no contienen marcas de solución; la comprobación se realiza
  exclusivamente mediante el endpoint del servidor.
- `flutter analyze --no-fatal-infos`: aprobado, sin incidencias.
- `flutter test`: aprobado, 12 pruebas.
- `flutter build web`: aprobado.
- Smoke Web/API/SQLite aprobado en un mismo origen local.
