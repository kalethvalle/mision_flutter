// datos_iniciales.js
// Ejecutar con:
// mongosh "mongodb://quest_app@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw" datos_iniciales.js

db = db.getSiblingDB("flutter_quest_dw");

for (const collectionName of [
  "students",
  "learning_catalog",
  "training_attempts",
  "assessment_attempts",
  "integrity_events",
  "teacher_metric_snapshots",
  "etl_runs"
]) {
  db.getCollection(collectionName).drop();
}

db.createCollection("students", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "username", "displayName", "role", "isActive", "createdAt"],
      properties: {
        _id: { bsonType: "string" },
        username: { bsonType: "string" },
        displayName: { bsonType: "string" },
        role: { enum: ["student"] },
        isActive: { bsonType: "bool" },
        createdAt: { bsonType: "date" }
      }
    }
  }
});

db.createCollection("learning_catalog", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "title", "status", "sortOrder", "topics", "missions"],
      properties: {
        _id: { bsonType: "string" },
        title: { bsonType: "string" },
        status: { enum: ["draft", "published"] },
        sortOrder: { bsonType: "int" },
        topics: { bsonType: "array" },
        missions: { bsonType: "array" }
      }
    }
  }
});

db.createCollection("training_attempts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "_id",
        "studentId",
        "worldId",
        "topicId",
        "missionId",
        "selectedOptionIds",
        "isCorrect",
        "hintUsed",
        "attemptedAt",
        "dateKey"
      ],
      properties: {
        _id: { bsonType: "string" },
        studentId: { bsonType: "string" },
        worldId: { bsonType: "string" },
        topicId: { bsonType: "string" },
        missionId: { bsonType: "string" },
        selectedOptionIds: { bsonType: "array", items: { bsonType: "string" } },
        isCorrect: { bsonType: "bool" },
        hintUsed: { bsonType: "bool" },
        contentVersion: { bsonType: "int" },
        attemptedAt: { bsonType: "date" },
        dateKey: { bsonType: "int" }
      }
    }
  }
});

db.createCollection("assessment_attempts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: [
        "_id",
        "studentId",
        "worldId",
        "status",
        "score",
        "passed",
        "correctAnswers",
        "totalQuestions",
        "incidents",
        "reactivationCount",
        "startedAt",
        "finishedAt"
      ],
      properties: {
        _id: { bsonType: "string" },
        studentId: { bsonType: "string" },
        studentName: { bsonType: "string" },
        worldId: { bsonType: "string" },
        worldTitle: { bsonType: "string" },
        sessionId: { bsonType: ["string", "null"] },
        status: { enum: ["submitted", "annulled"] },
        score: { bsonType: "int", minimum: 0, maximum: 100 },
        passed: { bsonType: "bool" },
        correctAnswers: { bsonType: "int", minimum: 0 },
        totalQuestions: { bsonType: "int", minimum: 0 },
        incidents: { bsonType: "int", minimum: 0 },
        reactivationCount: { bsonType: "int", minimum: 0 },
        topicScores: { bsonType: "array" },
        questionReview: { bsonType: "array" },
        startedAt: { bsonType: "date" },
        finishedAt: { bsonType: "date" }
      }
    }
  }
});

db.createCollection("integrity_events", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["_id", "studentId", "worldId", "type", "score", "occurredAt", "dateKey"],
      properties: {
        _id: { bsonType: "string" },
        studentId: { bsonType: "string" },
        studentName: { bsonType: "string" },
        worldId: { bsonType: "string" },
        attemptId: { bsonType: ["string", "null"] },
        sessionId: { bsonType: ["string", "null"] },
        type: {
          enum: [
            "fullscreen_exit",
            "focus_lost",
            "blocked_key",
            "expired",
            "annulled",
            "reactivated"
          ]
        },
        score: { bsonType: "int", minimum: 0 },
        occurredAt: { bsonType: "date" },
        dateKey: { bsonType: "int" }
      }
    }
  }
});

db.createCollection("teacher_metric_snapshots");
db.createCollection("etl_runs");

db.students.createIndex({ username: 1 }, { unique: true });
db.students.createIndex({ isActive: 1, displayName: 1 });

db.learning_catalog.createIndex({ status: 1, sortOrder: 1 });

db.training_attempts.createIndex({ studentId: 1, attemptedAt: -1 });
db.training_attempts.createIndex({ worldId: 1, topicId: 1, attemptedAt: -1 });
db.training_attempts.createIndex({ missionId: 1, attemptedAt: -1 });

db.assessment_attempts.createIndex({ studentId: 1, finishedAt: -1 });
db.assessment_attempts.createIndex({ worldId: 1, status: 1, finishedAt: -1 });
db.assessment_attempts.createIndex({ sessionId: 1, status: 1 });

db.integrity_events.createIndex({ studentId: 1, occurredAt: -1 });
db.integrity_events.createIndex({ type: 1, occurredAt: -1 });
db.integrity_events.createIndex({ attemptId: 1, occurredAt: -1 });

db.teacher_metric_snapshots.createIndex({ refreshedAt: -1 });
db.teacher_metric_snapshots.createIndex({ runId: 1 });
db.etl_runs.createIndex({ startedAt: -1 });

const runId = "etl_20261115_001";
const refreshedAt = new Date("2026-11-15T10:19:00.000Z");

db.students.insertMany([
  {
    _id: "student_1",
    username: "ana.perez",
    displayName: "Ana Perez",
    role: "student",
    isActive: true,
    createdAt: new Date("2026-11-15T08:00:00.000Z")
  },
  {
    _id: "student_2",
    username: "luis.rojas",
    displayName: "Luis Rojas",
    role: "student",
    isActive: true,
    createdAt: new Date("2026-11-15T08:05:00.000Z")
  }
]);

db.learning_catalog.insertMany([
  {
    _id: "world_1",
    title: "Fundamentos de Dart",
    status: "published",
    sortOrder: 1,
    topics: [
      { id: "topic_types", title: "Tipos de datos", status: "published" },
      { id: "topic_lists", title: "Listas", status: "published" }
    ],
    missions: [
      {
        id: "mission_variables",
        topicId: "topic_types",
        title: "Variables",
        selectionType: "single",
        contentVersion: 1,
        status: "published"
      },
      {
        id: "mission_lists",
        topicId: "topic_lists",
        title: "Listas basicas",
        selectionType: "multiple",
        contentVersion: 1,
        status: "published"
      }
    ]
  },
  {
    _id: "world_2",
    title: "Layouts y Flexbox",
    status: "published",
    sortOrder: 2,
    topics: [
      { id: "topic_column", title: "Column", status: "published" },
      { id: "topic_row", title: "Row", status: "published" }
    ],
    missions: [
      {
        id: "mission_column",
        topicId: "topic_column",
        title: "Column basico",
        selectionType: "single",
        contentVersion: 1,
        status: "published"
      }
    ]
  }
]);

db.training_attempts.insertMany([
  {
    _id: "ta_001",
    studentId: "student_1",
    worldId: "world_1",
    topicId: "topic_types",
    missionId: "mission_variables",
    selectedOptionIds: ["int"],
    isCorrect: true,
    hintUsed: false,
    contentVersion: 1,
    attemptedAt: new Date("2026-11-15T09:10:00.000Z"),
    dateKey: 20261115
  },
  {
    _id: "ta_002",
    studentId: "student_1",
    worldId: "world_1",
    topicId: "topic_lists",
    missionId: "mission_lists",
    selectedOptionIds: ["list", "map"],
    isCorrect: false,
    hintUsed: true,
    contentVersion: 1,
    attemptedAt: new Date("2026-11-15T09:18:00.000Z"),
    dateKey: 20261115
  },
  {
    _id: "ta_003",
    studentId: "student_2",
    worldId: "world_1",
    topicId: "topic_types",
    missionId: "mission_variables",
    selectedOptionIds: ["int"],
    isCorrect: true,
    hintUsed: true,
    contentVersion: 1,
    attemptedAt: new Date("2026-11-15T09:30:00.000Z"),
    dateKey: 20261115
  }
]);

db.assessment_attempts.insertMany([
  {
    _id: "aa_001",
    studentId: "student_1",
    studentName: "Ana Perez",
    worldId: "world_1",
    worldTitle: "Fundamentos de Dart",
    sessionId: "session_world_1_001",
    status: "submitted",
    score: 90,
    passed: true,
    correctAnswers: 9,
    totalQuestions: 10,
    incidents: 1,
    reactivationCount: 0,
    startedAt: new Date("2026-11-15T10:00:00.000Z"),
    finishedAt: new Date("2026-11-15T10:18:00.000Z"),
    topicScores: [
      {
        topicId: "topic_types",
        topicTitle: "Tipos de datos",
        correctAnswers: 5,
        totalQuestions: 5,
        score: 100
      },
      {
        topicId: "topic_lists",
        topicTitle: "Listas",
        correctAnswers: 4,
        totalQuestions: 5,
        score: 80
      }
    ],
    questionReview: [
      {
        questionId: "q_001",
        topicId: "topic_types",
        wasCorrect: true,
        selectedOptionIds: ["a"],
        correctOptionIds: ["a"]
      }
    ]
  },
  {
    _id: "aa_002",
    studentId: "student_2",
    studentName: "Luis Rojas",
    worldId: "world_1",
    worldTitle: "Fundamentos de Dart",
    sessionId: "session_world_1_001",
    status: "annulled",
    score: 0,
    passed: false,
    correctAnswers: 0,
    totalQuestions: 10,
    incidents: 3,
    reactivationCount: 1,
    startedAt: new Date("2026-11-15T10:01:00.000Z"),
    finishedAt: new Date("2026-11-15T10:12:00.000Z"),
    topicScores: [],
    questionReview: []
  }
]);

db.integrity_events.insertMany([
  {
    _id: "ie_001",
    studentId: "student_1",
    studentName: "Ana Perez",
    worldId: "world_1",
    attemptId: "aa_001",
    sessionId: "session_world_1_001",
    type: "fullscreen_exit",
    score: 1,
    occurredAt: new Date("2026-11-15T10:05:00.000Z"),
    dateKey: 20261115
  },
  {
    _id: "ie_002",
    studentId: "student_2",
    studentName: "Luis Rojas",
    worldId: "world_1",
    attemptId: "aa_002",
    sessionId: "session_world_1_001",
    type: "annulled",
    score: 3,
    occurredAt: new Date("2026-11-15T10:12:00.000Z"),
    dateKey: 20261115
  }
]);

db.teacher_metric_snapshots.insertOne({
  _id: "snapshot_20261115_101900",
  runId,
  refreshedAt,
  summary: {
    totalStudents: 2,
    activeStudents: 2,
    completedMissions: 2,
    trainingAttempts: 3,
    trainingAccuracy: 67,
    averageAssessmentScore: 45,
    approvalRate: 50,
    incidents: 2,
    annulledAttempts: 1
  },
  studentEvolution: [
    {
      studentId: "student_1",
      studentName: "Ana Perez",
      activeDays: 1,
      completedMissions: 1,
      totalMissions: 3,
      trainingAccuracy: 50,
      recentTrainingAccuracy: 50,
      bestAssessmentScore: 90,
      latestAssessmentScore: 90
    },
    {
      studentId: "student_2",
      studentName: "Luis Rojas",
      activeDays: 1,
      completedMissions: 1,
      totalMissions: 3,
      trainingAccuracy: 100,
      recentTrainingAccuracy: 100,
      bestAssessmentScore: 0,
      latestAssessmentScore: 0
    }
  ],
  academicPerformance: [
    {
      studentId: "student_1",
      studentName: "Ana Perez",
      averageScore: 90,
      approvedAttempts: 1,
      totalAttempts: 1,
      trainingAccuracy: 50,
      trainingAssessmentGap: -40
    },
    {
      studentId: "student_2",
      studentName: "Luis Rojas",
      averageScore: 0,
      approvedAttempts: 0,
      totalAttempts: 1,
      trainingAccuracy: 100,
      trainingAssessmentGap: 100
    }
  ],
  topicDifficulty: [
    {
      topicId: "topic_lists",
      topicTitle: "Listas",
      worldTitle: "Fundamentos de Dart",
      trainingAccuracy: 0,
      assessmentScore: 80,
      attempts: 2
    },
    {
      topicId: "topic_types",
      topicTitle: "Tipos de datos",
      worldTitle: "Fundamentos de Dart",
      trainingAccuracy: 100,
      assessmentScore: 100,
      attempts: 3
    }
  ],
  integrity: [
    {
      studentId: "student_2",
      studentName: "Luis Rojas",
      incidents: 1,
      annulledAttempts: 1,
      reactivations: 1,
      riskLevel: "alto"
    },
    {
      studentId: "student_1",
      studentName: "Ana Perez",
      incidents: 1,
      annulledAttempts: 0,
      reactivations: 0,
      riskLevel: "medio"
    }
  ]
});

db.etl_runs.insertOne({
  _id: runId,
  source: "sqlite-export-demo",
  status: "completed",
  startedAt: new Date("2026-11-15T10:18:30.000Z"),
  finishedAt: refreshedAt,
  counts: {
    students: db.students.countDocuments(),
    learningCatalog: db.learning_catalog.countDocuments(),
    trainingAttempts: db.training_attempts.countDocuments(),
    assessmentAttempts: db.assessment_attempts.countDocuments(),
    integrityEvents: db.integrity_events.countDocuments(),
    snapshots: db.teacher_metric_snapshots.countDocuments()
  }
});

print("Base flutter_quest_dw creada correctamente.");
printjson({
  students: db.students.countDocuments(),
  catalog: db.learning_catalog.countDocuments(),
  trainingAttempts: db.training_attempts.countDocuments(),
  assessmentAttempts: db.assessment_attempts.countDocuments(),
  integrityEvents: db.integrity_events.countDocuments(),
  snapshots: db.teacher_metric_snapshots.countDocuments()
});
