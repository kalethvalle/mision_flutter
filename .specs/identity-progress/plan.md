# Plan: identity-progress

- Estado: Completada
- Rama: `feature/identity-progress`
- Especificación: [spec.md](./spec.md)
- Historias: [stories-users.md](../../docs/stories-users.md)
- Contexto: [context.md](../context.md)

## Fase 0 — Línea base SDD

- [x] Revisar HU-04, HU-05, HU-06 y la secuencia SDD.
- [x] Confirmar que `catalog-foundation` aún no está en `origin/develop`.
- [x] Crear la rama apilada sobre el commit verificado de la fase 1.
- [x] Preservar `devtools_options.yaml` como archivo ajeno no versionado.
- [x] Ejecutar análisis y pruebas de línea base.

## Fase 1 — Identidad y criptografía

- [x] Añadir modelos, contratos y casos de uso de identidad.
- [x] Implementar Argon2id con sal segura y comparación constante.
- [x] Generar IDs y tokens con `Random.secure`.
- [x] Crear migración 2 para usuarios, sesiones, intentos y progreso.
- [x] Implementar bootstrap atómico del primer docente.
- [x] Implementar login, sesión expirable, logout y limpieza de sesiones.
- [x] Implementar creación/listado de estudiantes con autorización docente.

## Fase 2 — Entrenamiento y progreso

- [x] Definir modelos y contratos de progreso por estudiante.
- [x] Calcular misiones/mundos disponibles desde catálogo publicado y progreso.
- [x] Registrar cada comprobación con usuario, opción, pista y versión.
- [x] Actualizar intento y progreso en una sola transacción.
- [x] Rechazar intentos de misiones bloqueadas desde el servidor.
- [x] Conservar primera fecha correcta y aislar información por usuario.

## Fase 3 — API y cliente HTTP

- [x] Añadir endpoints de bootstrap, login, logout, perfil y usuarios.
- [x] Añadir endpoint de progreso y autenticar la comprobación.
- [x] Implementar cookies HttpOnly y códigos `401`/`403` estables.
- [x] Proteger catálogo y operaciones privadas con sesión.
- [x] Ampliar el repositorio HTTP con identidad y progreso.
- [x] Registrar uso de pista en el contrato de comprobación.

## Fase 4 — Flutter Web

- [x] Crear gate de sesión con bootstrap, login y errores.
- [x] Crear vista docente para alta y listado de estudiantes.
- [x] Mostrar perfil y cierre de sesión.
- [x] Cargar progreso al iniciar y después de cada acierto.
- [x] Mostrar avance por mundo y motivo de bloqueo.
- [x] Bloquear navegación siguiente hasta completar la misión actual.
- [x] Limpiar stores al cerrar o cambiar de sesión.
- [x] Validar presentación móvil y escritorio.

## Fase 5 — Pruebas y cierre

- [x] Probar hashing, bootstrap único, login y sesiones vencidas.
- [x] Probar autorización docente/estudiante.
- [x] Probar intentos transaccionales y uso de pista.
- [x] Probar secuencia completa de nueve misiones y reinicio.
- [x] Probar aislamiento entre dos estudiantes.
- [x] Probar API sin filtración de credenciales/tokens.
- [x] Probar widgets de bootstrap, login, docente y estudiante.
- [x] Ejecutar `flutter analyze --no-fatal-infos`.
- [x] Ejecutar `flutter test`.
- [x] Ejecutar `flutter build web`.
- [x] Ejecutar smoke Web/API/SQLite con reinicio de servidor.
- [x] Actualizar README, spec, plan y finalmente `context.md`.
- [x] Crear el commit `feat: persist identity and progress`.
- [x] Mantener la rama sin merge ni push.

## Riesgos

- **Costo criptográfico:** parámetros seguros configurables en pruebas, sin
  reducir los valores usados por el servidor real.
- **Sesión cruzada:** token opaco almacenado como hash y usuario resuelto solo
  en servidor.
- **Progreso inconsistente:** intento y avance dentro de la misma transacción.
- **Salto de misión:** la regla se aplica otra vez en API, no solo en widgets.
- **Rama apilada:** antes de integrar esta feature debe fusionarse primero
  `catalog-foundation` y actualizar la base de la rama si corresponde.

## Resultado

Implementación completada y verificada el 2026-10-30. La aplicación crea el
docente inicial, permite administrar estudiantes, autentica sesiones locales y
persiste intentos, uso de pistas, avance y desbloqueos aislados por estudiante.
