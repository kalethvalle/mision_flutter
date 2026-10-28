# Plan: mission-guidance

- Estado: Completada
- Rama: `feature/mission-guidance`
- Especificación: [spec.md](./spec.md)
- Contexto: [context.md](../context.md)

## Implementación

- [x] Actualizar `develop` mediante fast-forward y crear la rama de feature.
- [x] Crear la documentación SDD inicial.
- [x] Ampliar el modelo y el contenido pedagógico de las nueve misiones.
- [x] Incorporar la tarjeta de guía y hacer desplazable el editor.
- [x] Mejorar la presentación responsive de los mundos.
- [x] Añadir pruebas de datos y widgets para los nuevos comportamientos.
- [x] Ejecutar análisis y pruebas.
- [x] Actualizar el contexto y cerrar la documentación SDD.
- [x] Registrar el commit final de la feature.

## Verificación esperada

- `flutter analyze --no-fatal-infos`: sin errores y sin avisos adicionales a
  los 11 heredados.
- `flutter test`: todas las pruebas aprobadas en tamaños móvil y escritorio.
- Git: rama activa `feature/mission-guidance`, basada en `develop` actualizado.

## Resultado

Feature completada el 2026-10-27. Las nueve misiones incluyen dos párrafos de
contexto, tres pasos y pistas sin la respuesta explícita. El mapa y las misiones
se validaron en móvil y escritorio. El análisis terminó sin errores ni avisos
nuevos y las 5 pruebas finalizaron correctamente.

