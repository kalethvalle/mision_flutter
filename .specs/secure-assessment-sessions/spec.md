# Secure Assessment Sessions

## Objetivo

Agregar parciales controlados por docente con activación por mundo,
temporizador sincronizado, pantalla completa estricta, incidentes auditables,
reactivación manual, monitoreo docente y reportes interpretables.

## Alcance

- El docente configura duración, pantalla completa, umbral de incidentes,
  gracia de retorno y modo estricto por mundo.
- El docente abre y cierra sesiones de parcial por mundo.
- El estudiante solo inicia un parcial si el mundo tiene sesión activa,
  misiones completas y preguntas publicadas.
- El intento registra respuestas parciales, incidentes, anulación automática,
  reactivación y entrega.
- El reporte docente conserva la fuente de verdad en SQLite/API e incluye
  duración, incidentes, reactivaciones, estado, nota y detalle por pregunta.

## No Objetivos

- No se promete bloqueo absoluto de teclas del sistema operativo en navegador.
- No se importan reportes HTML externos como autoridad académica.
- No se rediseña por completo el banco de preguntas ni la lógica de snapshots.

## Requisitos

- La sesión activa del mundo define el deadline del intento.
- Estudiantes que entren tarde reciben el tiempo restante de la sesión.
- Cerrar sesión impide nuevos intentos.
- Incidentes de fullscreen, foco, visibilidad, teclas bloqueadas y abandono
  quedan persistidos.
- El modo estricto anula al superar el umbral de incidentes configurado.
- El docente puede reactivar un intento anulado con motivo obligatorio.
- El monitoreo no muestra respuestas en vivo antes de la entrega; muestra
  progreso, incidentes y nota al finalizar.

## Seguridad y Permisos

- Solo docentes gestionan sesiones, configuraciones, reactivaciones, SSE y
  reportes detallados.
- Solo estudiantes inician, actualizan borradores, reportan incidentes y
  entregan sus propios intentos.
- Las soluciones siguen ocultas en intentos abiertos.

## Riesgos

- Fullscreen y bloqueo de teclado son best effort en Flutter Web.
- SSE es local/en memoria; la bitácora persistente es la fuente auditable.
- La migración reconstruye tablas de intentos para ampliar el `CHECK` de
  estado a `annulled`.

## Criterios de Aceptación

- No se puede iniciar parcial sin sesión activa.
- Un intento vencido o con incidentes excedidos queda anulado.
- El docente puede reactivar y la bitácora conserva ambos eventos.
- La vista docente permite configurar, activar, cerrar y observar intentos.
- El reporte muestra estado, nota, duración, incidentes, temas y detalle por
  pregunta.
