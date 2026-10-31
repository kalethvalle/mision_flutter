# Plan: content-authoring

- Estado: Completada
- Rama: `feature/content-authoring`
- Especificación: [spec.md](./spec.md)
- Historias: [stories-users.md](../../docs/stories-users.md)
- Contexto: [context.md](../context.md)

## Fase 0 — Preparación

- [x] Revisar HU-07, HU-08 y la secuencia SDD.
- [x] Confirmar `develop` actualizado y crear la rama.
- [x] Ejecutar análisis y pruebas de línea base.
- [x] Preservar `devtools_options.yaml` sin versionar.

## Fase 1 — Dominio y persistencia

- [x] Definir modelos, contratos y validaciones de autoría.
- [x] Crear migración 3 para preguntas y opciones versionables.
- [x] Implementar repositorio SQLite transaccional.
- [x] Excluir borradores del catálogo y del banco publicable.
- [x] Incrementar versión sin alterar intentos históricos.

## Fase 2 — API y cliente

- [x] Crear endpoints docentes de consulta, creación y edición.
- [x] Aplicar autenticación y autorización por rol.
- [x] Devolver validaciones de publicación completas y estables.
- [x] Ampliar el repositorio HTTP con autoría.

## Fase 3 — Flutter Web

- [x] Incorporar store de autoría al flujo docente.
- [x] Separar estudiantes, contenido y preguntas en pestañas.
- [x] Crear formularios de mundos, temas, misiones y preguntas.
- [x] Mostrar borrador/publicado, versión y errores.
- [x] Verificar diseño responsive.

## Fase 4 — Pruebas y cierre

- [x] Probar borradores, publicación y persistencia tras reinicio.
- [x] Probar reglas de misiones y preguntas single/multiple.
- [x] Probar permisos anónimo, estudiante y docente.
- [x] Probar visibilidad estudiantil y conservación de intentos.
- [x] Probar widgets del editor en móvil y escritorio.
- [x] Ejecutar `flutter analyze --no-fatal-infos`.
- [x] Ejecutar `flutter test` y `flutter build web`.
- [x] Ejecutar smoke Web/API/SQLite.
- [x] Actualizar README, spec, plan y finalmente `context.md`.
- [x] Crear el commit `feat: add content authoring`.
- [x] Mantener la rama sin merge ni push.

## Riesgos

- **Historial:** conservar IDs y versiones; nunca borrar intentos al editar.
- **Contenido inválido:** validar publicación en servidor y transacción.
- **Filtración de soluciones:** separar API docente del catálogo estudiantil.
- **Plantillas no soportadas:** aceptar solo el registro fijo compartido.

## Resultado

Implementación completada y verificada el 2026-10-30. El docente puede crear y
editar mundos, temas, misiones y preguntas, conservar borradores y publicar
contenido validado sin exponer soluciones ni alterar intentos históricos.
