# Especificación: content-authoring

- Estado: Completada
- Rama: `feature/content-authoring`
- Base: `develop` (`e9e5160`)
- Fecha de inicio: 2026-10-30
- Fecha de finalización: 2026-10-30
- Historias relacionadas: HU-07 y HU-08

## Objetivo

Permitir que un docente autenticado cree y edite mundos, temas, misiones de
plantilla y preguntas evaluables desde Flutter Web. El contenido puede
guardarse como borrador incompleto; solo los registros que cumplen todas las
reglas de publicación se muestran a estudiantes o quedan disponibles para los
parciales de una fase posterior.

## Modelo de autoría

- Mundo: título, descripción, icono permitido, color hexadecimal, orden y estado.
- Tema: mundo, título, descripción, orden y estado.
- Misión: mundo, tema, categoría, orden, objetivo, dos párrafos, tres pasos,
  pista, plantilla, marcador, vista previa permitida, opciones y estado.
- Pregunta: mundo, tema, enunciado, tipo `single` o `multiple`, explicación,
  opciones, versión y estado.
- Todo registro usa un ID estable generado en el servidor. Misiones y preguntas
  incrementan `contentVersion` en cada edición.

## Borradores y publicación

- Un borrador exige solo relaciones existentes, orden positivo y los datos
  estructurales necesarios para persistirlo.
- Un mundo publicado requiere título, descripción, icono y color válidos.
- Un tema publicado requiere textos completos y un mundo publicado.
- Una misión publicada requiere padres publicados, dos párrafos, tres pasos,
  pista, plantilla con su marcador, vista previa registrada, al menos dos
  opciones y exactamente una correcta.
- Una pregunta publicada requiere padres publicados, enunciado, explicación,
  al menos dos opciones y solución. `single` exige exactamente una correcta;
  `multiple` exige una o más correctas.
- Los errores de publicación devuelven todas las faltas detectadas en un mensaje
  estable y no aplican cambios parciales.

## Autorización y API

- Todos los endpoints `/api/v1/authoring/*` requieren sesión docente.
- Estudiantes y solicitudes anónimas reciben `403` y `401`, respectivamente.
- `GET /api/v1/authoring` devuelve borradores, publicados, soluciones y los
  tipos de vista previa permitidos exclusivamente al docente.
- `POST` crea y `PUT /:id` actualiza mundos, temas, misiones y preguntas.
- El catálogo estudiantil continúa mostrando solo padres y misiones publicadas,
  sin marcas de respuesta correcta.

## Persistencia e historial

- La migración 3 crea `questions` y `question_options` y habilita opciones de
  misión activas/inactivas para conservar referencias de intentos previos.
- Cada guardado compuesto se ejecuta dentro de una transacción SQLite.
- Editar contenido no actualiza ni elimina `training_attempts`,
  `mission_progress` ni sus versiones registradas.
- Las preguntas publicadas podrán ser seleccionadas por la fase de parciales;
  los borradores quedan excluidos por estado.

## Interfaz docente

- El panel docente tendrá pestañas de estudiantes, contenido y preguntas.
- Contenido permite filtrar, crear y editar mundos, temas y misiones.
- Preguntas permite crear y editar el banco por mundo, tema, tipo y estado.
- Los formularios muestran el estado, la versión y errores de validación.
- La presentación debe funcionar en anchos móvil y escritorio sin overflow.

## Criterios de aceptación

1. Un docente guarda un borrador incompleto y lo recupera tras reiniciar.
2. Publicar una misión incompleta enumera sus faltas y no la publica.
3. Una misión válida publicada aparece en el mundo del estudiante.
4. Solo se aceptan categorías y vistas previas implementadas.
5. Tema y pregunta siempre pertenecen al mismo mundo seleccionado.
6. Selección única exige una correcta; múltiple admite una o más.
7. Preguntas publicadas y borradores se distinguen de forma persistente.
8. Estudiantes no pueden leer ni modificar el espacio de autoría.
9. Editar una misión incrementa versión sin cambiar intentos existentes.
10. Análisis, pruebas, build web y smoke local finalizan correctamente.

## Fuera de alcance

- Ejecutar código Dart arbitrario o crear nuevos tipos de vista previa.
- Eliminar contenido, reordenar automáticamente o importar/exportar archivos.
- Generación con IA, parciales, calificación e informes.
- Edición de cuentas o adaptador SQLite nativo para Android.
- Fusionar o publicar automáticamente la rama.

## Verificación final

- `flutter analyze --no-fatal-infos`: sin hallazgos.
- `flutter test`: 25 pruebas aprobadas.
- `flutter build web`: compilación completada.
- Smoke local: web/API/SQLite, sesión docente, guardado de borrador y
  recuperación después de reiniciar el servidor aprobados.
