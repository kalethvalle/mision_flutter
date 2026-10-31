# Especificación: identity-progress

- Estado: Completada
- Rama: `feature/identity-progress`
- Base técnica: `feature/catalog-foundation` (`6a3b6b9`)
- Base SDD prevista: `develop` después de fusionar `catalog-foundation`
- Fecha de inicio: 2026-10-30
- Fecha de finalización: 2026-10-30
- Historias relacionadas: HU-04, HU-05 y HU-06

## Objetivo

Incorporar identidad local, sesiones y progreso persistente por estudiante.
Cada comprobación de entrenamiento quedará asociada a la cuenta autenticada y
la navegación se desbloqueará únicamente al completar las misiones publicadas
en orden, incluso después de reiniciar navegador y servidor.

## Identidad local

- Si no existen usuarios, la interfaz solicitará crear el docente inicial.
- El docente inicial define nombre, usuario y clave; no habrá credenciales
  predeterminadas ni claves impresas en logs.
- El docente puede crear cuentas de estudiantes y consultar la lista local.
- El usuario normalizado es único, no distingue mayúsculas y admite de 3 a 32
  caracteres alfanuméricos, punto, guion y guion bajo.
- Las claves tendrán entre 10 y 128 caracteres.
- Las claves se almacenarán con Argon2id, sal aleatoria individual y parámetros
  persistidos: 19 MiB, dos iteraciones, paralelismo uno y hash de 32 bytes.
- No se almacenarán ni transportarán claves en texto plano fuera de la petición
  de creación o inicio de sesión.

## Sesiones y autorización

- Una autenticación válida crea un token aleatorio de 256 bits.
- SQLite guarda únicamente el SHA-256 del token y su vencimiento.
- El navegador recibe una cookie `HttpOnly`, `SameSite=Strict`, `Path=/`, con
  duración de 12 horas. No se marca `Secure` porque el servidor local usa HTTP.
- Cerrar sesión invalida el token en SQLite y elimina la cookie.
- Bootstrap y login son públicos; catálogo, progreso, comprobación y gestión de
  estudiantes requieren sesión.
- Solo `teacher` puede listar o crear estudiantes. Solo `student` mantiene
  intentos y progreso de entrenamiento.
- El cliente no decide permisos ni identidad mediante campos enviados al API.

## Persistencia

La migración 2 añadirá:

- `users`: identidad, rol, estado y parámetros/hash de clave.
- `sessions`: hash del token, usuario, creación, vencimiento y último uso.
- `training_attempts`: usuario, misión, opción, acierto, uso de pista, fecha y
  versión del contenido.
- `mission_progress`: usuario, misión, fecha de primer acierto y último intento.

Crear un intento y actualizar progreso tras un acierto será una sola
transacción. Los errores no borran progreso y los aciertos repetidos conservan
la primera fecha de finalización.

## Reglas de progreso

- La primera misión publicada del primer mundo está disponible para un
  estudiante nuevo.
- Una misión se completa al registrar al menos un intento correcto.
- La siguiente misión del mismo mundo se habilita cuando la anterior está
  completa. Las misiones completadas siempre pueden revisitarse.
- Un mundo posterior se habilita cuando todas las misiones publicadas del mundo
  anterior están completas.
- El servidor vuelve a calcular disponibilidad con el catálogo publicado; no
  acepta intentos para una misión bloqueada aunque se invoque el API directo.
- Un estudiante nunca recibe progreso ni intentos de otra cuenta.
- La flecha siguiente permanece deshabilitada mientras la siguiente misión esté
  bloqueada; acertar la actual refresca el progreso y la habilita.

## API HTTP

| Método y ruta | Acceso | Resultado |
| --- | --- | --- |
| `GET /api/v1/auth/status` | Público | Indica si falta crear el docente inicial. |
| `POST /api/v1/auth/bootstrap` | Público una vez | Crea docente y sesión inicial. |
| `POST /api/v1/auth/login` | Público | Autentica y crea sesión. |
| `POST /api/v1/auth/logout` | Autenticado | Invalida sesión y cookie. |
| `GET /api/v1/auth/me` | Autenticado | Devuelve el perfil activo. |
| `GET /api/v1/users` | Docente | Lista cuentas locales sin hashes. |
| `POST /api/v1/users` | Docente | Crea una cuenta estudiantil. |
| `GET /api/v1/progress` | Estudiante | Devuelve disponibilidad y avance propios. |
| `POST /api/v1/missions/:id/check` | Estudiante | Guarda intento y actualiza progreso. |

La comprobación acepta `optionId` y `hintUsed`. Ninguna respuesta pública
incluye hashes de claves, sales, tokens ni identificadores de otros usuarios.

## Interfaz

- Mostrar estados de inicialización, bootstrap, login y error recuperable.
- El docente verá su perfil, cierre de sesión, lista y formulario de estudiantes.
- El estudiante verá su nombre, cierre de sesión y mapa personalizado.
- Las tarjetas mostrarán misiones completadas/total y el requisito de bloqueo.
- La vista de misión mostrará estado completado, bloqueará avance indebido y
  registrará el uso de pista al abrirla.
- Cerrar sesión descarta inmediatamente el estado en memoria del usuario previo.

## Criterios de aceptación

1. Una base sin usuarios permite crear exactamente un docente inicial; un
   segundo bootstrap es rechazado.
2. La base nunca contiene claves ni tokens de sesión en texto plano.
3. Docente puede crear estudiantes; estudiantes no pueden administrar cuentas.
4. Dos estudiantes conservan intentos y progreso aislados.
5. Cada comprobación registra opción, acierto, pista, fecha, usuario y versión.
6. Error no habilita avance; acierto habilita solo la siguiente misión.
7. Mundo 2 se abre solo después de completar las cinco misiones publicadas del
   Mundo 1 y continúa abierto tras reiniciar servidor y volver a iniciar sesión.
8. Invocar directamente una misión bloqueada devuelve error sin crear intento.
9. Sesión inválida o vencida devuelve `401`; rol incorrecto devuelve `403`.
10. Mapa y misiones funcionan en móvil y escritorio sin overflow.
11. Análisis, pruebas, build web y smoke local finalizan correctamente.

## Restricciones y fuera de alcance

- No implementar recuperación/cambio de clave ni edición/eliminación de cuentas.
- No implementar autoría, banco de preguntas, parciales o informes.
- No persistir el estado visual de una opción seleccionada.
- No publicar el servidor en red ni añadir proveedores externos de identidad.
- No declarar Android verificado ni añadir aún su adaptador SQLite.
- No fusionar ni publicar automáticamente la rama.
- No actualizar `.specs/context.md` hasta completar toda la feature.

## Referencias

- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [`Argon2id` en `package:cryptography`](https://pub.dev/documentation/cryptography/latest/cryptography/Argon2id-class.html)

## Verificación final

- `flutter analyze`: sin hallazgos.
- `flutter test`: todas las pruebas aprobadas.
- `flutter build web`: compilación completada.
- Smoke local: web, API, bootstrap, alta e ingreso de estudiante, intento y
  recuperación de progreso después de reiniciar el servidor aprobados.
