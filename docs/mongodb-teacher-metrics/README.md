# Entregable MongoDB - Metricas Docentes Flutter Quest

Este paquete plantea MongoDB como data warehouse documental para las metricas
que revisa el docente en `mision_flutter`. No reemplaza SQLite/API: MongoDB
queda como capa derivada para analitica, respaldo y sustentacion.

## Archivos del entregable

- `documento-diseno.md`: base del PDF de fases 1 y 2.
- `datos_iniciales.js`: crea colecciones, validadores, indices y datos demo.
- `consultas.js`: consultas, actualizaciones, agregaciones e indices.
- `crud_demo.js`: programa Node.js de conexion y CRUD sin contrasenas.

## Instalacion local con Docker

```bash
docker run -d --name flutter-quest-mongo \
  -p 27017:27017 \
  -e MONGO_INITDB_ROOT_USERNAME=admin \
  -e MONGO_INITDB_ROOT_PASSWORD='cambia-esto' \
  mongo:7
```

Entrar como administrador:

```bash
docker exec -it flutter-quest-mongo mongosh "mongodb://admin:cambia-esto@localhost:27017/admin"
```

Crear usuario de aplicacion:

```javascript
use flutter_quest_dw
db.createUser({
  user: "quest_app",
  pwd: "cambia-esto",
  roles: [{ role: "readWrite", db: "flutter_quest_dw" }]
})
```

Conectar como aplicacion:

```bash
docker exec -it flutter-quest-mongo mongosh "mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw"
```

Los comandos anteriores usan `docker exec -it flutter-quest-mongo` porque
`mongosh` se ejecuta dentro del contenedor. Si cambias la clave de `quest_app`,
actualiza tambien la URI.

## Ejecutar scripts

Desde esta carpeta:

```bash
docker exec -i flutter-quest-mongo mongosh "mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw" < datos_iniciales.js
docker exec -i flutter-quest-mongo mongosh "mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw" < consultas.js
```

`-i` mantiene abierto stdin para enviar el contenido del archivo `.js` al
`mongosh` del contenedor. `-it` se usa solo cuando quieres una consola
interactiva.

## Programa CRUD

```bash
npm init -y
npm install mongodb
export MONGODB_URI="mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw"
node crud_demo.js
```

## Respaldo o export JSON

Respaldo completo:

```bash
docker exec -i flutter-quest-mongo mongodump --uri="mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw" --out=/tmp/backup-flutter-quest-dw
docker cp flutter-quest-mongo:/tmp/backup-flutter-quest-dw ./backup-flutter-quest-dw
zip -r backup-flutter-quest-dw.zip backup-flutter-quest-dw
```

Export JSON:

```bash
docker exec -i flutter-quest-mongo mongoexport --uri="mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw" --collection=teacher_metric_snapshots --jsonArray > teacher_metric_snapshots.json
docker exec -i flutter-quest-mongo mongoexport --uri="mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw" --collection=assessment_attempts --jsonArray > assessment_attempts.json
docker exec -i flutter-quest-mongo mongoexport --uri="mongodb://quest_app:cambia-esto@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw" --collection=integrity_events --jsonArray > integrity_events.json
```

## Convertir el documento a PDF

Opcion simple: abrir `documento-diseno.md` en VS Code y exportarlo con una
extension Markdown PDF.

Opcion CLI:

```bash
pandoc documento-diseno.md -o documento-diseno.pdf
```

## Checklist para entregar

- PDF: `documento-diseno.pdf`.
- Script de creacion/datos: `datos_iniciales.js`.
- Script de consultas/agregaciones/indices: `consultas.js`.
- Backup: `backup-flutter-quest-dw.zip` o JSON exportados.
- CRUD: `crud_demo.js`.
- Repositorio: README explicando instalacion y ejecucion.
- Sustentacion: mostrar usuario `readWrite`, seed, consulta KPI, ranking por
  estudiante, dificultad por tema, eventos de integridad y CRUD.
