# Despliegue Docker en Ubuntu con Cloudflare Tunnel

Esta guía despliega Flutter Quest como aplicación web servida por el servidor
Dart incluido en el proyecto. El contenedor entrega `build/web` y la API
`/api/v1` desde el mismo origen, con SQLite persistente en un volumen Docker.

## Arquitectura

```text
Internet
  -> Cloudflare
  -> Cloudflare Tunnel ya registrado
  -> localhost:18081 en el servidor Ubuntu
  -> Docker 127.0.0.1:18081:8080
  -> bin/server.dart
  -> /app/data/flutter_quest.sqlite3
```

Trade-off: este despliegue mantiene el modelo monolito local del proyecto y lo
hace accesible por dominio. No convierte la aplicación Android en offline ni
reemplaza SQLite por una base multiusuario externa.

## Requisitos

- Servidor Ubuntu con Docker y Docker Compose instalados.
- Tunnel de Cloudflare ya dado de alta.
- Public hostname del tunnel apuntando al servicio `http://localhost:18081`.
- Repositorio disponible en el servidor.
- Puerto `18081` libre en loopback. Si está ocupado, usa otro puerto y ajusta el
  mapeo Docker y el servicio del tunnel.

## Dockerfile

El repositorio incluye `Dockerfile` en la raíz del proyecto:

```dockerfile
FROM debian:bookworm-slim AS build

ARG FLUTTER_VERSION=3.47.9
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
        zip \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter \
    && flutter --version \
    && dart --version \
    && flutter config --enable-web

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release
RUN dart build cli --target bin/server.dart -o /tmp/flutter_quest_server

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /tmp/flutter_quest_server/bundle /app/server_bundle
COPY --from=build /app/build/web /app/build/web

RUN mkdir -p /app/data

EXPOSE 8080

CMD ["/app/server_bundle/bin/server", "--host", "0.0.0.0", "--port", "8080", "--database", "/app/data/flutter_quest.sqlite3", "--web-root", "/app/build/web"]
```

El repositorio también incluye `.dockerignore` para evitar subir artefactos
locales al contexto de build:

```dockerignore
.dart_tool/
.git/
.idea/
.vscode/
build/
data/
docs/mongodb-teacher-metrics/node_modules/
*.log
```

## Compose de la aplicación

El repositorio incluye `compose.prod.yaml` en la raíz del proyecto:

```yaml
services:
  flutter-quest:
    build:
      context: .
      dockerfile: Dockerfile
      args:
        FLUTTER_VERSION: ${FLUTTER_VERSION:-3.47.9}
    container_name: flutter-quest
    restart: unless-stopped
    ports:
      - "127.0.0.1:18081:8080"
    volumes:
      - flutter_quest_data:/app/data

volumes:
  flutter_quest_data:
```

No publiques el puerto en `0.0.0.0`. Cloudflare Tunnel debe ser la entrada
pública; Docker solo escucha en `127.0.0.1` del servidor.

## Despliegue

Desde la raíz del proyecto en el servidor:

```sh
docker compose -f compose.prod.yaml build
docker compose -f compose.prod.yaml up -d
docker compose -f compose.prod.yaml logs -f flutter-quest
```

Si tu Ubuntu usa Compose legacy, reemplaza `docker compose` por
`docker-compose`.

El proyecto exige Dart `^3.13.0`. El Dockerfile instala Flutter `3.47.9`, que
usa Dart `3.13.7`, para evitar imágenes Docker de Flutter desactualizadas. Si
necesitas fijar otra versión compatible:

```sh
FLUTTER_VERSION=3.47.9 docker compose -f compose.prod.yaml build --no-cache
FLUTTER_VERSION=3.47.9 docker compose -f compose.prod.yaml up -d
```

Con Compose legacy:

```sh
FLUTTER_VERSION=3.47.9 docker-compose -f compose.prod.yaml build --no-cache
FLUTTER_VERSION=3.47.9 docker-compose -f compose.prod.yaml up -d
```

El servidor se construye con `dart build cli`, no con `dart compile exe`,
porque la dependencia `sqlite3` usa build hooks/native assets.

Valida en el servidor:

```sh
curl http://127.0.0.1:18081/api/v1/health
```

La primera ejecución crea `/app/data/flutter_quest.sqlite3` dentro del volumen
`flutter_quest_data`, aplica migraciones y carga el catálogo inicial.

## Configuración del tunnel

En Cloudflare Zero Trust, el public hostname del tunnel debe enrutar al servicio:

```text
http://localhost:18081
```

Si el tunnel ya existe y solo falta ajustar el destino, cambia el `Service URL`
del hostname. Si `18081` está ocupado, por ejemplo usa `18082`:

```yaml
ports:
  - "127.0.0.1:18082:8080"
```

Y en Cloudflare:

```text
http://localhost:18082
```

## Variante: cloudflared también en Docker

Usa esta variante solo si no vas a ejecutar `cloudflared` como servicio del
host. En Ubuntu, para que `localhost` sea el localhost real del servidor, el
contenedor de `cloudflared` debe usar red del host:

```yaml
services:
  flutter-quest:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: flutter-quest
    restart: unless-stopped
    ports:
      - "127.0.0.1:18081:8080"
    volumes:
      - flutter_quest_data:/app/data

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: flutter-quest-cloudflared
    restart: unless-stopped
    network_mode: host
    command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TUNNEL_TOKEN}
    environment:
      CLOUDFLARE_TUNNEL_TOKEN: ${CLOUDFLARE_TUNNEL_TOKEN}

volumes:
  flutter_quest_data:
```

Guarda el token en `.env` y no lo subas al repositorio:

```sh
CLOUDFLARE_TUNNEL_TOKEN=pega_aqui_el_token
```

Luego:

```sh
docker compose --env-file .env -f compose.prod.yaml up -d
```

## Operación

Ver estado:

```sh
docker compose -f compose.prod.yaml ps
docker compose -f compose.prod.yaml logs --tail=100 flutter-quest
```

Reiniciar:

```sh
docker compose -f compose.prod.yaml restart flutter-quest
```

Actualizar versión:

```sh
git pull
docker compose -f compose.prod.yaml build --no-cache flutter-quest
docker compose -f compose.prod.yaml up -d
```

Respaldar SQLite:

```sh
docker compose -f compose.prod.yaml exec flutter-quest cp /app/data/flutter_quest.sqlite3 /app/data/flutter_quest.backup.sqlite3
docker cp flutter-quest:/app/data/flutter_quest.backup.sqlite3 ./flutter_quest.backup.sqlite3
```

## Problemas frecuentes

- **502 en Cloudflare:** el tunnel está sano, pero no llega al servicio. Revisa
  que `curl http://127.0.0.1:18081/api/v1/health` responda en Ubuntu y que el
  `Service URL` del hostname use el mismo puerto.
- **Connection refused:** el contenedor no está arriba, el puerto cambió o
  `cloudflared` está en Docker sin `network_mode: host`.
- **Pantalla carga pero login falla:** revisa logs del contenedor; puede faltar
  permiso de escritura en el volumen o haber una base dañada.
- **No se ven cambios tras actualizar:** reconstruye la imagen; `flutter build
  web` ocurre dentro del Dockerfile.
- **No expongas SQLite:** solo debe existir como volumen interno. La entrada
  pública es el tunnel hacia HTTP.

