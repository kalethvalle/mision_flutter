# Especificación: mission-guidance

- Estado: Completada
- Rama: `feature/mission-guidance`
- Rama base: `develop`
- Fecha: 2026-10-27

## Objetivo

Mejorar la orientación pedagógica previa a cada ejercicio para que el usuario
comprenda qué aprenderá y cómo abordar la misión antes de seleccionar una
respuesta. La mejora cubre las nueve misiones y las tarjetas de los dos mundos.

## Requisitos funcionales

- Cada misión conserva su objetivo y añade exactamente dos párrafos de contexto:
  el primero presenta el concepto y el segundo lo relaciona con el ejercicio.
- El primer párrafo ocupa como máximo cuatro líneas y el segundo tres líneas.
- Cada misión incluye exactamente tres pasos numerados, con un máximo de dos
  líneas por paso.
- La tarjeta `Antes de comenzar` es el primer contenido del panel editor y
  permanece visible sin exigir confirmación.
- Las pistas orientan conceptualmente sin incluir el identificador ni el texto
  exacto de la opción correcta.
- En móvil, el editor aparece antes de la vista previa; en escritorio permanece
  a la izquierda.
- El panel editor permite desplazamiento para conservar acceso al código, las
  opciones y el botón en alturas reducidas.
- Cada tarjeta de mundo destaca `Qué aprenderás` y adapta el botón al ancho
  disponible.

## Restricciones

- No cambiar opciones, respuestas correctas, validación, navegación, progreso
  ni desbloqueo.
- No añadir enlaces externos a la interfaz.
- Fundamentar el contenido en la documentación oficial de Dart y Flutter.
- No introducir errores ni nuevos avisos del analizador.

## Criterios de aceptación

- Las nueve misiones contienen dos párrafos, tres instrucciones y una pista no
  vacía.
- Los límites visuales son `4 + 3` líneas para contexto y `3 × 2` para pasos.
- El mapa muestra el aprendizaje de ambos mundos con una distribución
  responsive sin overflow.
- La guía cambia al navegar entre misiones.
- `flutter analyze --no-fatal-infos` finaliza sin errores ni avisos nuevos.
- `flutter test` finaliza con todas las pruebas aprobadas.

## Fuera de alcance

- Nuevos mundos o ejercicios.
- Persistencia, autenticación o servicios remotos.
- Modificación del sistema de progreso.
- Fusión o publicación automática de la rama.

## Validación

- `flutter analyze --no-fatal-infos`: aprobado, sin errores ni avisos nuevos;
  permanecen los 11 avisos informativos heredados.
- `flutter test`: aprobado, 5 pruebas ejecutadas.
- Validación responsive aprobada en 390 × 844 y 1200 × 900.
- Validación completada el 2026-10-27.

