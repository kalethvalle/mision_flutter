# Instructivo Docente De Flutter Quest

Este instructivo explica el flujo mínimo para preparar contenido, abrir
parciales y revisar resultados.

## Ruta Recomendada

1. Crea o revisa los estudiantes.
2. Crea el mundo.
3. Crea los temas del mundo.
4. Crea las misiones de entrenamiento.
5. Crea las preguntas del parcial.
6. Activa el parcial cuando el grupo esté listo.
7. Revisa resultados y métricas.

## Crear Estudiantes

Entra al panel docente y abre la pestaña `ESTUDIANTES`.

- Escribe el nombre del estudiante.
- Define un usuario fácil de identificar.
- Asigna una clave inicial de mínimo 10 caracteres.
- Guarda el estudiante.

Buenas prácticas:

- Usa nombres reales o nombres institucionales consistentes.
- No reutilices usuarios entre estudiantes.
- Crea los estudiantes antes de activar parciales.

## Crear Mundos

Abre `CONTENIDO` y usa `NUEVO MUNDO`.

Un mundo representa una unidad grande de aprendizaje, por ejemplo
`Fundamentos de Dart` o `Layouts en Flutter`.

Campos recomendados:

- `Título`: nombre claro de la unidad.
- `Descripción`: qué aprenderá el estudiante.
- `Icono`: señal visual del mundo.
- `Color hexadecimal`: color distintivo del mundo.
- `Orden`: posición en la ruta.
- `Estado`: usa `Borrador` mientras preparas; usa `Publicado` cuando esté
  listo para estudiantes.

Buenas prácticas:

- Mantén pocos mundos por curso o corte académico.
- Publica un mundo solo cuando tenga temas y misiones suficientes.
- Ordena los mundos de menor a mayor dificultad.

## Crear Temas

En `CONTENIDO`, usa `NUEVO TEMA`.

Un tema agrupa un concepto dentro de un mundo, por ejemplo `Tipos numéricos`,
`Listas` o `Column`.

Campos recomendados:

- `Mundo`: unidad a la que pertenece.
- `Título`: concepto que se trabajará.
- `Descripción`: qué debe comprender el estudiante.
- `Orden dentro del mundo`: secuencia del tema.
- `Estado`: publica cuando esté listo.

Buenas prácticas:

- Un tema debe ser concreto.
- Evita mezclar varios conceptos difíciles en un mismo tema.
- Ordena los temas como los explicarías en clase.

## Crear Misiones

En `CONTENIDO`, usa `NUEVA MISIÓN`.

Una misión es un ejercicio de entrenamiento. El estudiante lee contexto,
observa una plantilla de código y elige una o varias opciones.

Campos clave:

- `Mundo` y `Tema`: ubican la misión.
- `Título`: nombre corto del ejercicio.
- `Objetivo`: qué practica la misión.
- `Párrafo conceptual`: explicación breve del concepto.
- `Aplicación de la misión`: para qué sirve en Flutter/Dart.
- `Paso 1`, `Paso 2`, `Paso 3`: guía de resolución.
- `Pista`: ayuda sin revelar la respuesta.
- `Vista previa`: tipo de visualización disponible.
- `Tipo de selección`: única o múltiple.
- `Plantilla de código`: código con marcador de respuesta.
- `Marcador de respuesta`: texto que será reemplazado por la opción.
- `Opciones`: una opción por línea con formato `id|etiqueta|código`.
- `IDs correctos`: ids correctos separados por coma.
- `Estado`: borrador o publicado.

Ejemplo de opciones:

```text
int|int|int age = 20;
string|String|String age = "20";
double|double|double age = 20.0;
```

Si la misión es de selección múltiple, puedes marcar varias respuestas:

```text
int,double
```

Buenas prácticas:

- La pista debe orientar, no regalar la respuesta.
- Usa selección múltiple solo cuando realmente haya varias respuestas
  correctas.
- Publica misiones después de probar que las opciones y el marcador funcionan.
- Mantén la dificultad progresiva.

## Crear Preguntas Para Parciales

Abre `PREGUNTAS` y usa `NUEVA PREGUNTA`.

Una pregunta pertenece a un mundo y tema. Al iniciar un parcial, el sistema
toma una copia de la pregunta publicada para conservar historial.

Campos clave:

- `Mundo` y `Tema`: ubican la pregunta.
- `Enunciado`: pregunta que verá el estudiante.
- `Tipo`: selección única o múltiple.
- `Explicación posterior`: explicación para la revisión después de entregar.
- `Opciones`: una opción por línea con formato `id|texto`.
- `IDs correctos`: ids correctos separados por coma.
- `Estado`: publica cuando esté lista.

Ejemplo:

```text
a|int representa enteros
b|String representa texto
c|bool representa verdadero o falso
```

Respuesta correcta:

```text
a
```

Buenas prácticas:

- No escribas pistas ni soluciones en el enunciado.
- La explicación posterior sí puede enseñar la solución.
- Publica preguntas suficientes antes de activar el parcial.
- Usa selección múltiple solo cuando el estudiante deba identificar un conjunto
  exacto.

## Configurar Y Activar Parciales

Abre `PARCIALES`.

Cada parcial se activa por mundo. El tiempo empieza cuando el docente activa la
sesión, no cuando cada estudiante entra.

Configuración recomendada:

- `Minutos`: duración total del parcial.
- `Incidentes`: máximo de infracciones antes de anulación automática.
- `Retorno s`: segundos permitidos para volver a pantalla completa.
- `Nota anulación`: nota asignada si el intento se anula.
- `Pantalla completa`: recomendable para parciales.
- `Estricto`: activa consecuencias por incidentes.

Flujo:

1. Ajusta la configuración del mundo.
2. Pulsa `GUARDAR CONFIGURACIÓN`.
3. Pulsa `ACTIVAR` cuando el grupo esté listo.
4. Monitorea estudiantes, progreso e incidentes.
5. Usa `REACTIVAR` solo si decides revertir una anulación.
6. Pulsa `CERRAR` cuando no deban entrar más estudiantes.

Buenas prácticas:

- Explica las reglas antes de activar.
- Activa el parcial cuando todos estén presentes.
- No uses reactivación sin un motivo claro.
- Revisa incidentes antes de tomar decisiones académicas.

## Revisar Resultados

Abre `RESULTADOS`.

Puedes filtrar por:

- estudiante
- mundo
- tema

La vista separa entrenamiento y parciales. En parciales puedes ver nota,
estado, temas, incidentes y detalle por pregunta.

Buenas prácticas:

- Revisa primero los intentos anulados o con incidentes.
- Usa el detalle por pregunta para identificar conceptos difíciles.
- Complementa la nota con el historial de entrenamiento.

## Revisar Métricas

Abre `MÉTRICAS`.

Esta vista resume:

- estudiantes activos
- precisión en Arena
- promedio de parciales
- aprobación
- temas críticos
- señales de integridad

Usa `RECALCULAR` después de una actividad o parcial importante.

Buenas prácticas:

- Usa temas críticos para reforzar clase.
- Compara entrenamiento contra parcial para detectar brechas.
- Mira integridad como señal de revisión, no como juicio automático.

## Recomendación De Trabajo Mínimo

Para una clase pequeña:

1. Un mundo.
2. Dos o tres temas.
3. Una o dos misiones por tema.
4. Tres a cinco preguntas de parcial.
5. Una sesión de parcial por mundo.

Este flujo evita trabajo extra y mantiene la experiencia clara para docentes y
estudiantes.
