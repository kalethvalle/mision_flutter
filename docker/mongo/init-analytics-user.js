const databaseName = process.env.MONGO_INITDB_DATABASE || "flutter_quest_dw";
const appUser = process.env.MONGODB_APP_USER || "quest_app";
const appPassword = process.env.MONGODB_APP_PASSWORD || "cambia-esto";

db = db.getSiblingDB(databaseName);

db.createUser({
  user: appUser,
  pwd: appPassword,
  roles: [{ role: "readWrite", db: databaseName }],
});

db.students.createIndex({ username: 1 });
db.learning_catalog.createIndex({ sortOrder: 1 });
db.training_attempts.createIndex({ studentId: 1, attemptedAt: -1 });
db.training_attempts.createIndex({ worldId: 1, topicId: 1, attemptedAt: -1 });
db.assessment_attempts.createIndex({ studentId: 1, finishedAt: -1 });
db.assessment_attempts.createIndex({ worldId: 1, status: 1, finishedAt: -1 });
db.integrity_events.createIndex({ studentId: 1, occurredAt: -1 });
db.integrity_events.createIndex({ attemptId: 1, occurredAt: -1 });
db.teacher_metric_snapshots.createIndex({ refreshedAt: -1 });
db.etl_runs.createIndex({ startedAt: -1 });
