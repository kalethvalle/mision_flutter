# Flutter Quest (`mision_flutter`)

Aplicación para practicar Dart y Flutter mediante mundos y misiones interactivas. Hoy incluye dos mundos y nueve misiones. El contenido y la respuesta correcta están definidos en Dart; el progreso vive en memoria y se pierde al cerrar la app. Todavía no existen cuentas, editor docente, SQLite ni parciales.

La [planificación SDD de las 12 historias de usuario](docs/stories-users.md) describe la arena, la persistencia local y el parcial formativo («jefe final») de cada mundo. Las especificaciones de las funciones ya completadas están en [`.specs`](.specs/context.md).

## Ejecutar la versión web actual en el PC

Requiere Flutter instalado y un navegador compatible. Desde la raíz del proyecto:

```sh
flutter doctor
flutter pub get
flutter run -d chrome
```

También se puede generar la versión estática con `flutter build web`; sus archivos quedan en `build/web/`. En el estado actual no se necesita servidor de API ni base de datos.

## Arquitectura web local planificada

Una fase posterior añadirá un servidor Dart dentro de este proyecto. Servirá la aplicación web compilada y su API desde `127.0.0.1`, y guardará las cuentas, el contenido y los resultados en `data/flutter_quest.sqlite3`, un archivo visible en el PC y excluido de Git. El navegador y la API compartirán origen. **Ese servidor y el archivo SQLite aún no existen**; por eso no hay un comando de arranque disponible para ellos. El procedimiento se añadirá aquí cuando estén implementados y verificados.

## Preparar y compilar Android

La compilación Android usa el proyecto Flutter existente. Se necesita Flutter, Android SDK y las licencias que indique `flutter doctor`. No hace falta iniciar un emulador para generar el APK:

```sh
flutter doctor
flutter pub get
flutter build apk --release
```

Si la compilación termina correctamente, el APK queda en `build/app/outputs/flutter-apk/app-release.apk`. El comando compila **la app actual**: todavía no incluye la persistencia ni los parciales planificados. En esta fase documental no se ejecutó ni verificó una compilación Android, por la limitación de memoria del equipo. Para la futura versión Android se prevé SQLite local en el dispositivo, reutilizando las entidades y casos de uso de la versión web.

Referencia: [compilación Android en la documentación de Flutter](https://docs.flutter.dev/deployment/android).
