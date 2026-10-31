# Plan: catalog-foundation

- Estado: Completada
- Rama: `feature/catalog-foundation`
- Rama base: `develop`
- Especificación: [spec.md](./spec.md)
- Historias: [stories-users.md](../../docs/stories-users.md)
- Contexto: [context.md](../context.md)

## Decisiones de planificación

- Entregar la ruta completa Flutter Web → API local → casos de uso → SQLite.
- Representar las nueve habilidades actuales como nueve temas estables.
- Mantener selección y desbloqueo en memoria hasta la fase de progreso.
- Comprobar respuestas en el servidor, pero no guardar intentos anónimos.
- Usar claves declarativas para iconos, colores y vistas previas; Flutter es el
  único responsable de convertirlas en elementos visuales.
- Servir Web y API desde el mismo origen local.

## Dependencias incorporadas

- Cliente: `http`.
- Servidor: `shelf`, `shelf_router` y `shelf_static`.
- Persistencia: `sqlite3` y `path`.

No se añadirá una librería de ORM ni generación de código en esta fase. El
esquema pequeño y sus migraciones se mantendrán explícitos y comprobables.

## Estructura objetivo

```text
bin/server.dart                         # entrada del servidor local
lib/core/models/                        # entidades y DTO Dart puros
lib/core/repositories/                  # interfaces y adaptador HTTP
lib/application/catalog/                # casos de uso
lib/server/api/                         # rutas y mapeo HTTP
lib/server/database/                    # conexión, migraciones y semilla
lib/server/repositories/                # adaptador SQLite
lib/features/home/                      # presentación y registro visual
```

Los módulos `lib/server` solo serán importados desde `bin/server.dart`. El
entrypoint Flutter no dependerá de `dart:io`, SQLite ni Shelf.

## Fase 0 — Línea base y contrato SDD

- [x] Confirmar `develop` limpio y actualizado con las 12 historias.
- [x] Crear `feature/catalog-foundation` desde `develop`.
- [x] Crear `spec.md` y `plan.md` sin modificar `context.md`.
- [x] Ejecutar y registrar la línea base de análisis, pruebas y build web.
- [x] Revisar que los nombres e IDs actuales sean estables antes de migrarlos.

## Fase 1 — Dominio y contratos

- [x] Crear entidades Dart puras para mundo, tema, misión y opción.
- [x] Separar campos editoriales, de dominio y de presentación declarativa.
- [x] Definir interfaces `CatalogRepository` y `MissionAnswerRepository`.
- [x] Implementar casos de uso de consulta e inspección de respuesta.
- [x] Definir DTO públicos y conversión JSON con validación de entrada.
- [x] Crear registros Flutter para `iconKey` y los nueve `previewType`.
- [x] Eliminar `Widget`, `IconData`, `Color` y `correctOptionId` de los modelos
      que cruzan el límite entre cliente y servidor.
- [x] Añadir pruebas unitarias de entidades, casos de uso y serialización.

## Fase 2 — SQLite, migraciones y semilla

- [x] Añadir `data/` a `.gitignore` sin versionar la base generada.
- [x] Implementar apertura configurable de SQLite y activación de foreign keys.
- [x] Crear el registro transaccional de migraciones de esquema.
- [x] Crear tablas, índices, restricciones de orden y claves foráneas.
- [x] Convertir los dos mundos y nueve misiones actuales en semilla de servidor.
- [x] Asociar cada misión con uno de los nueve temas definidos.
- [x] Hacer idempotente la semilla con IDs deterministas y conflictos explícitos.
- [x] Implementar repositorios SQLite con consultas parametrizadas.
- [x] Probar base nueva, migración repetida, integridad referencial, orden y
      ausencia de duplicados usando archivos temporales.

## Fase 3 — API y servidor local

- [x] Construir el `Handler` de Shelf con middleware de JSON, errores y log.
- [x] Implementar `health`, mundos, misiones, detalle y comprobación.
- [x] Garantizar que los DTO de lectura omitan toda marca de respuesta correcta.
- [x] Validar cuerpos JSON, existencia, publicación y pertenencia de la opción.
- [x] Servir `build/web` y fallback de navegación a `index.html`.
- [x] Configurar host, puerto, ruta de base y web root con valores locales
      predeterminados y argumentos de línea de comandos.
- [x] Cerrar recursos de manera ordenada ante señales de terminación.
- [x] Añadir pruebas del handler sin red y una prueba HTTP de integración local.

## Fase 4 — Adaptación de Flutter Web

- [x] Implementar el repositorio HTTP con `Client` inyectado.
- [x] Cargar mundos y misiones de manera asíncrona desde `GameStore`.
- [x] Modelar estados `initial`, `loading`, `ready`, `empty` y `failure`.
- [x] Presentar errores recuperables con una acción de reintento.
- [x] Mantener selección, navegación y desbloqueo actual en memoria.
- [x] Reemplazar la comparación local por `CheckMissionAnswer` remoto.
- [x] Mantener la vista previa inmediata mediante el registro local.
- [x] Evitar resultados tardíos de una misión después de navegar a otra.
- [x] Adaptar las pruebas de widgets con repositorios falsos deterministas.

## Fase 5 — Verificación de aceptación

- [x] Ejecutar migraciones y semilla dos veces; comprobar 2 mundos, 9 temas y
      9 misiones sin duplicados.
- [x] Comprobar por API el orden y la ausencia de soluciones en lecturas.
- [x] Probar respuesta correcta, incorrecta, opción ajena, misión inexistente y
      JSON inválido.
- [x] Validar las nueve misiones y ambos mundos contra el contenido previo.
- [x] Validar mapa y misión en 390 × 844 y 1200 × 900 sin overflow.
- [x] Validar estado visible con servidor detenido y recuperación por reintento.
- [x] Integrar las pruebas puras y de servidor en la suite `flutter test`.
- [x] Ejecutar `flutter analyze --no-fatal-infos` sin errores ni avisos nuevos.
- [x] Ejecutar `flutter test` con todas las pruebas aprobadas.
- [x] Ejecutar `flutter build web` correctamente.
- [x] Iniciar el servidor con una base temporal y comprobar Web/API en el mismo
      origen mediante smoke test local.

## Fase 6 — Cierre SDD

- [x] Registrar comandos, cantidades y resultados reales en esta planificación.
- [x] Actualizar el estado y la validación de `spec.md`.
- [x] Actualizar `.specs/context.md` solo después de completar la verificación.
- [x] Documentar comandos de ejecución local y arquitectura vigente en README.
- [x] Revisar que no se hayan versionado la base ni artefactos de `build/`.
- [x] Crear el commit `feat: establish catalog foundation`.
- [x] Mantener la rama sin fusionar ni publicar automáticamente.

## Matriz mínima de pruebas

| Nivel | Casos principales |
| --- | --- |
| Dominio | Orden, filtros publicados, validación de opción y errores tipados. |
| SQLite | Primera migración, repetición, semilla, restricciones y consultas. |
| API | JSON, estados HTTP, no filtración de soluciones y mismo handler estático. |
| Flutter | Carga, error/reintento, mapa, guía, selección, preview y feedback. |
| Integración | Reinicio sin duplicados y recorrido Web → API → SQLite. |

## Riesgos y mitigaciones

- **Acoplamiento Flutter/dominio:** impedir imports de Flutter en entidades y
  comprobar que el servidor se ejecute con `dart run`.
- **Filtración de soluciones:** usar DTO públicos separados y pruebas negativas
  sobre todos los endpoints de lectura.
- **Diferencias respecto al catálogo actual:** usar IDs estables y pruebas de
  paridad para cada mundo, misión, párrafo, paso y opción.
- **Respuestas asíncronas fuera de orden:** invalidar solicitudes al cambiar de
  misión y comprobar el identificador antes de actualizar el estado.
- **SQLite bloqueado o inaccesible:** transacciones breves, cierre ordenado y
  error explícito en la interfaz; nunca recurrir a datos falsos.
- **Build web servido desde una ruta inexistente:** validar al inicio y devolver
  un error accionable sin afectar el endpoint de salud.

## Validación ejecutada

- Línea base: 11 avisos informativos, 5 pruebas y build web aprobado.
- `flutter analyze --no-fatal-infos`: aprobado, sin incidencias.
- `flutter test`: aprobado, 12 pruebas.
- `flutter build web`: aprobado, incluido el dry run de WebAssembly.
- SQLite: una migración, 2 mundos, 9 temas, 9 misiones, 18 párrafos,
  27 instrucciones y 27 opciones; segunda inicialización sin duplicados.
- Smoke local: `GET /api/v1/health`, catálogo, comprobación y `/` respondieron
  correctamente desde `127.0.0.1:8097` con una base temporal.

## Resultado

Feature completada el 2026-10-27. HU-01 a HU-03 consumen el catálogo mediante
repositorios y HU-04 valida en el servidor sin filtrar soluciones en lecturas.
Identidad, historial de intentos y progreso persistente continúan en la fase 2.
