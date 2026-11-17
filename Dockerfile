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