# Despliegue Docker con SQLite y MongoDB analitico

## Modo SQLite

Este modo conserva el comportamiento actual y no requiere MongoDB.

```sh
docker compose -f compose.sqlite.yaml up --build -d
docker compose -f compose.sqlite.yaml logs -f flutter-quest
```

La aplicacion queda en:

```text
http://127.0.0.1:18081
```

El volumen `flutter_quest_sqlite_data` persiste
`/app/data/flutter_quest.sqlite3`.

## Modo SQLite + MongoDB para metricas

Este modo mantiene SQLite como fuente de verdad y habilita MongoDB para
snapshots y colecciones derivadas de analitica docente.

1. Copia `.env.example` a `.env` fuera de cualquier commit y cambia los valores
   `cambia-esto`.
2. Levanta los servicios:

```sh
docker compose --env-file .env -f compose.mongo-analytics.yaml up --build -d
docker compose -f compose.mongo-analytics.yaml logs -f flutter-quest
```

3. Entra como docente y ejecuta el refresh desde la pestaña `METRICAS`.

Variables principales:

| Variable | Valor esperado |
| --- | --- |
| `ANALYTICS_STORE` | `sqlite` o `mongo` |
| `ANALYTICS_REFRESH_MODE` | `manual` |
| `MONGODB_URI` | URI interna hacia `mongo:27017` |
| `MONGODB_DATABASE` | `flutter_quest_dw` |
| `FLUTTER_QUEST_HOST_PORT` | Puerto local del backend web/API |

## Verificacion operativa

```sh
docker compose -f compose.sqlite.yaml config
docker compose --env-file .env -f compose.mongo-analytics.yaml config
```

Consulta del contenedor MongoDB:

```sh
docker exec -it flutter-quest-analytics-mongo \
  mongosh "mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw"
```

Validaciones utiles dentro de `mongosh`:

```javascript
db.teacher_metric_snapshots.findOne({ _id: "current" })
db.etl_runs.find().sort({ startedAt: -1 }).limit(5)
db.training_attempts.countDocuments()
db.assessment_attempts.countDocuments()
```

## Rollback

Para volver al modo actual, define:

```env
ANALYTICS_STORE=sqlite
```

o levanta el compose SQLite:

```sh
docker compose -f compose.sqlite.yaml up -d
```

MongoDB es derivado. Borrar sus colecciones o su volumen no elimina usuarios,
progreso, parciales ni calificaciones oficiales porque esos datos siguen en
SQLite.
