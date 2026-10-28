# Historias de usuario y planificación SDD — Flutter Quest

- Estado: planificación; este documento no implica que las funciones pendientes estén implementadas.
- Producto: arena local de entrenamiento en Dart y Flutter, seguida de un parcial formativo («jefe final») por mundo.
- Entrega inicial prevista: Flutter Web en un PC, con servidor Dart local y un archivo SQLite visible.

## 1. Punto de partida

La aplicación actual tiene dos mundos y nueve misiones escritas en Dart: cinco de fundamentos de Dart y cuatro de layouts. Cada misión presenta contexto, tres pasos, pista, plantilla de código, opciones, una respuesta correcta y una vista previa. `GameStore` guarda selección, acierto y desbloqueo en memoria. No hay cuentas, SQLite, historial de intentos, editor docente ni parciales. Hoy se puede avanzar con la flecha sin resolver la misión y acertar la última misión del primer mundo basta para desbloquear el segundo. HU-05 especifica el cambio de esa regla.

El proyecto clínico `ctlt-monte-sinai` aporta la idea de organizar zona → pregunta → opciones y registrar opciones seleccionadas. Sus opciones son observaciones clínicas sin respuesta correcta: no se importan preguntas, respuestas ni datos de pacientes. Flutter Quest necesita contenido educativo propio, solución y explicación para cada pregunta evaluable.

## 2. Objetivo, usuarios y reglas transversales

- **Estudiante:** practica misiones, consulta su progreso y presenta el parcial de cada mundo.
- **Docente:** administra mundos, misiones basadas en plantillas y preguntas; consulta resultados desde el mismo PC.
- **Perfiles:** cada persona usa una cuenta local con clave y rol `student` o `teacher`. En la primera apertura se crea la cuenta docente inicial; el docente crea cuentas de estudiantes. Las claves se guardan como hash con sal, nunca en texto plano. Cada acción y registro se asocia al perfil autenticado.
- **Entrenamiento:** permite pistas, corrección inmediata y nuevos intentos. Completar una misión exige acertarla al menos una vez; los errores no borran el progreso.
- **Parcial:** se habilita cuando todas las misiones publicadas del mundo están completas. Usa preguntas publicadas de los temas de ese mundo; si no hay preguntas, se muestra como no disponible. No muestra pistas ni soluciones antes de entregar. La nota es `100 × aciertos / preguntas`, aprueba con nota ≥ 80, admite intentos ilimitados y conserva cada resultado. En selección múltiple, un acierto exige elegir exactamente el conjunto de opciones correctas; una pregunta vacía cuenta como incorrecta. La explicación se muestra después de entregar.
- **Contenido:** el editor permite crear y cambiar textos, instrucciones, pistas, plantillas de código y opciones dentro de tipos de misión y vistas previas predefinidos. No ejecuta código Dart libre ni genera widgets desde texto. Los cambios publicados aplican a nuevos intentos; los intentos cerrados conservan la versión de preguntas y respuestas evaluada.

## 3. Arquitectura y persistencia previstas

```text
Flutter Web (presentación)
  → API HTTP del servidor Dart local
  → casos de uso y entidades del dominio
  → interfaces de repositorio
  → adaptadores SQLite
  → data/flutter_quest.sqlite3

Flutter Android (fase posterior)
  → presentación → mismos casos de uso e interfaces
  → adaptadores SQLite nativos en el dispositivo
```

Es un monolito local dentro del mismo proyecto: el servidor Dart sirve los archivos compilados de Flutter Web y la API desde `127.0.0.1`, con un mismo origen. El navegador no accede al archivo SQLite directamente. El directorio `data/` se crea localmente y se excluye de Git. Si el servidor no puede abrir la base, la interfaz muestra el error y no simula que guardó cambios. Se usarán migraciones de esquema y una carga inicial idempotente de los dos mundos y nueve misiones actuales; reiniciar el servidor no duplicará contenido.

**Entidades mínimas:** `User` (rol y hash de clave), `World` (orden y estado), `Mission` (mundo, tema, tipo de vista previa, guía y plantilla), `MissionOption`, `Question` (mundo/tema, tipo, explicación y versión), `QuestionOption` (marca correcta), `TrainingAttempt`, `MissionProgress`, `AssessmentAttempt` y `AssessmentAnswer`. Los identificadores son estables; cada intento almacena fecha, usuario y versión del contenido que resolvió. `MissionProgress` distingue completado de simple visita. Los datos de cuentas y resultados no se incluyen en el repositorio.

**Contratos de repositorio:** autenticar y administrar perfiles; listar y publicar mundos, misiones y preguntas; guardar y consultar intentos de entrenamiento; consultar y actualizar progreso; iniciar y cerrar un parcial; consultar resultados por estudiante, mundo y tema. La presentación no lee tablas ni SQL. El servidor aplica autorización y validaciones; no confía en respuestas correctas enviadas desde el navegador. Android reutilizará el dominio y los casos de uso y cambiará el adaptador de datos.

## 4. Historias de usuario

### HU-01 — Explorar mundos

- **Actor y objetivo:** como estudiante, quiero ver mundos, temas y disponibilidad para elegir qué aprender.
- **Estado y dependencias:** existe el mapa de dos mundos; la disponibilidad actual vive en memoria. Depende de catálogo y progreso persistido.
- **Reglas:** mostrar mundos publicados en orden; el primero queda abierto y los demás siguen la regla de HU-05. Un mundo bloqueado indica qué falta.
- **Aceptación:** Dado un estudiante nuevo, cuando abre el mapa, entonces ve el Mundo 1 disponible y el Mundo 2 bloqueado. Dado un estudiante que completó el Mundo 1, cuando vuelve a abrir el mapa, entonces ve el Mundo 2 disponible.

### HU-02 — Consultar la guía de misión

- **Actor y objetivo:** como estudiante, quiero leer la explicación, los pasos y una pista antes de resolver.
- **Estado y dependencias:** existe en las nueve misiones Dart; depende del catálogo consultado por repositorio.
- **Reglas:** conservar dos párrafos, tres pasos y la pista por misión; la pista no revela la opción correcta.
- **Aceptación:** Dada una misión publicada, cuando entro, entonces veo su guía antes del ejercicio. Cuando cambio de misión, entonces se muestra la guía correspondiente a la nueva misión.

### HU-03 — Resolver una misión

- **Actor y objetivo:** como estudiante, quiero elegir una opción y ver cómo completa el fragmento y la vista previa.
- **Estado y dependencias:** existe la selección única en código; depende de catálogo, tipos de vista previa permitidos y HU-02.
- **Reglas:** solo se seleccionan opciones de la misión actual; el tipo de vista previa pertenece al registro de plantillas admitidas. El botón de probar requiere selección.
- **Aceptación:** Dada una misión con opciones, cuando selecciono una, entonces el fragmento y la vista previa reflejan la elección. Cuando retiro la selección, entonces no puedo probar la respuesta.

### HU-04 — Recibir retroalimentación

- **Actor y objetivo:** como estudiante, quiero saber si acerté y volver a intentarlo si fallé.
- **Estado y dependencias:** existe la comprobación inmediata, sin historial. Depende de HU-03 y del registro de intentos.
- **Reglas:** cada pulsación de probar guarda opción, acierto, fecha y uso de pista; solo un acierto completa la misión. Los errores permiten otra elección.
- **Aceptación:** Dada una opción incorrecta, cuando la pruebo, entonces veo el error y puedo reintentar. Dada la opción correcta, cuando la pruebo, entonces veo éxito y queda un intento correcto asociado a mi cuenta.

### HU-05 — Avanzar y desbloquear

- **Actor y objetivo:** como estudiante, quiero que mi avance y los desbloqueos reflejen las misiones resueltas.
- **Estado y dependencias:** parcial; hoy la flecha permite saltar y basta acertar la última misión. Depende de HU-04 y HU-06.
- **Reglas:** una misión se completa con al menos un acierto; la siguiente se habilita al completar la anterior. El siguiente mundo se abre solo cuando todas las misiones publicadas del mundo previo están completas. Volver a misiones completadas está permitido.
- **Aceptación:** Dado un error en la misión actual, cuando intento avanzar, entonces sigo bloqueado. Dadas todas las misiones del primer mundo completadas, cuando vuelvo al mapa, entonces el segundo mundo aparece abierto, también tras reiniciar.

### HU-06 — Recuperar el progreso

- **Actor y objetivo:** como estudiante, quiero retomar mi entrenamiento tras cerrar la aplicación.
- **Estado y dependencias:** pendiente; exige perfiles y SQLite.
- **Reglas:** persistir progreso e intentos por usuario; una nueva sesión no debe atribuir datos de otro estudiante. Guardar un intento y actualizar progreso se hace de forma consistente.
- **Aceptación:** Dado un estudiante con misiones completadas, cuando cierra y vuelve a abrir la app e inicia sesión, entonces conserva el progreso. Cuando entra otro estudiante, entonces ve únicamente su avance.

### HU-07 — Editar contenido

- **Actor y objetivo:** como docente, quiero crear y editar mundos, misiones y preguntas desde la aplicación.
- **Estado y dependencias:** pendiente; exige perfiles, catálogo persistido y registro de plantillas.
- **Reglas:** solo el rol docente accede al editor. Una misión puede quedar en borrador; para publicarla requiere mundo, orden, tema, guía, plantilla compatible, opciones y exactamente una solución de entrenamiento. El docente solo elige tipos de vista previa implementados. No se modifica el historial de intentos cerrados.
- **Aceptación:** Dado un docente autenticado, cuando guarda un borrador, entonces puede retomarlo. Cuando publica una misión válida, entonces aparece en el mundo elegido. Dado un estudiante, cuando intenta abrir el editor, entonces se deniega el acceso.

### HU-08 — Mantener el banco de preguntas

- **Actor y objetivo:** como docente, quiero preparar preguntas evaluables para cada tema entrenado.
- **Estado y dependencias:** pendiente; depende de HU-07 y del catálogo de mundos y temas.
- **Reglas:** pregunta en borrador o publicada; enunciado, mundo, tema, tipo, al menos dos opciones, solución y explicación son obligatorios para publicar. En selección única hay exactamente una opción correcta; en múltiple puede haber varias. Una pregunta no puede asociarse a un mundo distinto del tema seleccionado.
- **Aceptación:** Dada una pregunta incompleta, cuando intento publicarla, entonces recibo las faltas concretas. Dada una pregunta válida y publicada, cuando se prepara el parcial del mundo, entonces puede seleccionarse; si queda en borrador, no aparece.

### HU-09 — Enfrentar al jefe final

- **Actor y objetivo:** como estudiante, quiero presentar un parcial sobre lo practicado en cada mundo.
- **Estado y dependencias:** pendiente; depende de HU-05, HU-06 y HU-08.
- **Reglas:** el parcial se abre tras completar todas las misiones publicadas del mundo y tener preguntas publicadas; solo usa preguntas de sus temas. Al iniciarlo se fija la versión y el conjunto de preguntas del intento. No hay tiempo límite ni pistas en esta versión.
- **Aceptación:** Dado un mundo incompleto, cuando intento abrir su parcial, entonces permanece bloqueado y veo qué misiones faltan. Dado un mundo completo con preguntas, cuando inicio el parcial, entonces recibo solo preguntas de ese mundo y puedo entregar una única vez ese intento.

### HU-10 — Recibir el resultado

- **Actor y objetivo:** como estudiante, quiero conocer la nota y qué temas debo repasar.
- **Estado y dependencias:** pendiente; depende de HU-09.
- **Reglas:** comparar respuestas en el servidor; nota de 0 a 100, aprobación desde 80 inclusive y desglose por tema. Las preguntas sin respuesta son errores. Mostrar solución y explicación solo tras cerrar el intento.
- **Aceptación:** Dado un parcial entregado, cuando veo el resultado, entonces encuentro nota, aprobación, aciertos por tema y explicaciones. Dado un intento abierto, cuando consulto sus preguntas, entonces no recibo soluciones ni explicaciones de corrección.

### HU-11 — Consultar resultados

- **Actor y objetivo:** como docente, quiero revisar intentos y dificultades de los estudiantes.
- **Estado y dependencias:** pendiente; depende de perfiles, HU-04 y HU-10.
- **Reglas:** el docente consulta por estudiante, mundo y tema; el estudiante solo consulta sus resultados. El informe distingue intentos de entrenamiento y parciales y conserva sus fechas.
- **Aceptación:** Dado un docente autenticado, cuando filtra un mundo, entonces ve intentos y desempeño por estudiante y tema. Dado un estudiante, cuando solicita el informe docente, entonces el acceso se deniega.

### HU-12 — Repetir el parcial

- **Actor y objetivo:** como estudiante, quiero volver a presentar un parcial para medir mi mejora.
- **Estado y dependencias:** pendiente; depende de HU-09 y HU-10.
- **Reglas:** intentos ilimitados; cada intento tiene su propio conjunto versionado, nota y fecha. El historial no se reemplaza al repetir.
- **Aceptación:** Dado un parcial terminado, cuando inicio otro intento, entonces respondo una nueva instancia. Cuando consulto mi historial, entonces veo todos los intentos y sus notas en orden cronológico.

## 5. Secuencia de trabajo SDD

1. **Base y migración del catálogo:** definir entidades, interfaces y adaptadores; cargar los dos mundos y nueve misiones actuales sin duplicados. Adaptar HU-01 a HU-04 a repositorios conservando su experiencia.
2. **Identidad y progreso:** crear perfiles locales, autenticación y persistencia; corregir HU-05 e implementar HU-06.
3. **Autoría:** crear editor de plantillas y banco de preguntas, con borradores y publicación; implementar HU-07 y HU-08.
4. **Parciales e informes:** implementar HU-09 a HU-12, puntuación, historial y acceso docente.
5. Para cada fase funcional crear `.specs/<feature>/spec.md` y `plan.md` en una rama `feature/<nombre>`, según `.specs/context.md`. Actualizar el contexto solo al completar y verificar la fase.

**Pruebas de aceptación previstas:** catálogo sin duplicados tras dos arranques; persistencia tras reiniciar servidor y navegador; aislamiento de estudiantes; bloqueo de navegación y parcial; validación de borradores y permisos; selección múltiple exacta; nota 80 aprobatoria; historial intacto después de editar contenido y repetir parcial. Probar la versión web en un navegador local y la lógica de dominio con repositorios de prueba. Android se documenta y se compila cuando haya recursos; no se declara probado en esta fase documental.

## 6. Evolución posterior

El docente podrá aportar código y pedir a un modelo propuestas de misiones de entrenamiento. Las propuestas serán borradores: el docente revisará su corrección, la plantilla de vista previa y el vínculo con los objetivos del mundo antes de publicarlas. El «jefe final» seguirá siendo el parcial formativo que reúne lo aprendido en ese mundo. La ejecución de código Dart arbitrario, la generación automática y la publicación sin revisión quedan fuera de la primera implementación.
