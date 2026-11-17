ARG FLUTTER_IMAGE=ghcr.io/cirruslabs/flutter:beta
FROM ${FLUTTER_IMAGE} AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release
RUN dart compile exe bin/server.dart -o /tmp/flutter_quest_server

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libsqlite3-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /tmp/flutter_quest_server /app/flutter_quest_server
COPY --from=build /app/build/web /app/build/web

RUN mkdir -p /app/data

EXPOSE 8080

CMD ["/app/flutter_quest_server", "--host", "0.0.0.0", "--port", "8080", "--database", "/app/data/flutter_quest.sqlite3", "--web-root", "/app/build/web"]
