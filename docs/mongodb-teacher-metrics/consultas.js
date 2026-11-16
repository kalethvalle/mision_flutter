// consultas.js
// Ejecutar despues de datos_iniciales.js:
// mongosh "mongodb://quest_app@localhost:27017/flutter_quest_dw?authSource=flutter_quest_dw" consultas.js

db = db.getSiblingDB("flutter_quest_dw");

print("\n1) Ultimo snapshot de metricas docentes");
printjson(
  db.teacher_metric_snapshots
    .find({}, { summary: 1, refreshedAt: 1 })
    .sort({ refreshedAt: -1 })
    .limit(1)
    .toArray()[0]
);

print("\n2) Evolucion por estudiante desde el snapshot");
const latestSnapshot = db.teacher_metric_snapshots
  .find({})
  .sort({ refreshedAt: -1 })
  .limit(1)
  .toArray()[0];
printjson(latestSnapshot ? latestSnapshot.studentEvolution : []);

print("\n3) Ranking academico calculado desde intentos de parcial");
printjson(
  db.assessment_attempts
    .aggregate([
      {
        $group: {
          _id: "$studentId",
          studentName: { $first: "$studentName" },
          averageScore: { $avg: "$score" },
          bestScore: { $max: "$score" },
          approvedAttempts: { $sum: { $cond: ["$passed", 1, 0] } },
          totalAttempts: { $sum: 1 },
          annulledAttempts: {
            $sum: { $cond: [{ $eq: ["$status", "annulled"] }, 1, 0] }
          }
        }
      },
      {
        $project: {
          _id: 0,
          studentId: "$_id",
          studentName: 1,
          averageScore: { $round: ["$averageScore", 0] },
          bestScore: 1,
          approvedAttempts: 1,
          totalAttempts: 1,
          annulledAttempts: 1
        }
      },
      { $sort: { averageScore: -1, bestScore: -1, studentName: 1 } }
    ])
    .toArray()
);

print("\n4) Dificultad por tema combinando entrenamiento y parcial");
printjson(
  db.training_attempts
    .aggregate([
      {
        $group: {
          _id: "$topicId",
          trainingCorrect: { $sum: { $cond: ["$isCorrect", 1, 0] } },
          trainingTotal: { $sum: 1 }
        }
      },
      {
        $lookup: {
          from: "assessment_attempts",
          let: { topicId: "$_id" },
          pipeline: [
            { $unwind: "$topicScores" },
            { $match: { $expr: { $eq: ["$topicScores.topicId", "$$topicId"] } } },
            {
              $group: {
                _id: "$topicScores.topicId",
                topicTitle: { $first: "$topicScores.topicTitle" },
                assessmentScore: { $avg: "$topicScores.score" },
                assessmentAttempts: { $sum: 1 }
              }
            }
          ],
          as: "assessment"
        }
      },
      { $unwind: { path: "$assessment", preserveNullAndEmptyArrays: true } },
      {
        $project: {
          _id: 0,
          topicId: "$_id",
          topicTitle: "$assessment.topicTitle",
          trainingAccuracy: {
            $round: [
              {
                $multiply: [
                  { $divide: ["$trainingCorrect", "$trainingTotal"] },
                  100
                ]
              },
              0
            ]
          },
          assessmentScore: { $round: [{ $ifNull: ["$assessment.assessmentScore", 0] }, 0] },
          attempts: {
            $add: ["$trainingTotal", { $ifNull: ["$assessment.assessmentAttempts", 0] }]
          }
        }
      },
      { $sort: { trainingAccuracy: 1, assessmentScore: 1, attempts: -1 } }
    ])
    .toArray()
);

print("\n5) Integridad por estudiante");
printjson(
  db.integrity_events
    .aggregate([
      {
        $group: {
          _id: "$studentId",
          studentName: { $first: "$studentName" },
          incidents: { $sum: 1 },
          score: { $sum: "$score" },
          types: { $addToSet: "$type" }
        }
      },
      {
        $lookup: {
          from: "assessment_attempts",
          localField: "_id",
          foreignField: "studentId",
          as: "attempts"
        }
      },
      {
        $project: {
          _id: 0,
          studentId: "$_id",
          studentName: 1,
          incidents: 1,
          score: 1,
          types: 1,
          annulledAttempts: {
            $size: {
              $filter: {
                input: "$attempts",
                as: "attempt",
                cond: { $eq: ["$$attempt.status", "annulled"] }
              }
            }
          },
          reactivations: { $sum: "$attempts.reactivationCount" },
          riskLevel: {
            $switch: {
              branches: [
                { case: { $gte: ["$score", 3] }, then: "alto" },
                { case: { $gte: ["$score", 1] }, then: "medio" }
              ],
              default: "bajo"
            }
          }
        }
      },
      { $sort: { score: -1, incidents: -1, studentName: 1 } }
    ])
    .toArray()
);

print("\n6) Sesion de parcial por mundo");
printjson(
  db.assessment_attempts
    .aggregate([
      {
        $group: {
          _id: { sessionId: "$sessionId", worldId: "$worldId" },
          worldTitle: { $first: "$worldTitle" },
          startedAt: { $min: "$startedAt" },
          finishedAt: { $max: "$finishedAt" },
          attempts: { $sum: 1 },
          submitted: { $sum: { $cond: [{ $eq: ["$status", "submitted"] }, 1, 0] } },
          annulled: { $sum: { $cond: [{ $eq: ["$status", "annulled"] }, 1, 0] } },
          averageScore: { $avg: "$score" },
          incidents: { $sum: "$incidents" }
        }
      },
      {
        $project: {
          _id: 0,
          sessionId: "$_id.sessionId",
          worldId: "$_id.worldId",
          worldTitle: 1,
          startedAt: 1,
          finishedAt: 1,
          attempts: 1,
          submitted: 1,
          annulled: 1,
          averageScore: { $round: ["$averageScore", 0] },
          incidents: 1
        }
      },
      { $sort: { startedAt: -1 } }
    ])
    .toArray()
);

print("\n7) Actualizacion: marcar un estudiante inactivo");
printjson(
  db.students.updateOne(
    { _id: "student_2" },
    { $set: { isActive: false, updatedAt: new Date() } }
  )
);

print("\n8) Actualizacion derivada: insertar snapshot minimo recalculado");
const totalStudents = db.students.countDocuments();
const activeStudents = db.students.countDocuments({ isActive: true });
const trainingAttempts = db.training_attempts.countDocuments();
const trainingCorrect = db.training_attempts.countDocuments({ isCorrect: true });
const assessmentSummary = db.assessment_attempts
  .aggregate([
    {
      $group: {
        _id: null,
        averageScore: { $avg: "$score" },
        approved: { $sum: { $cond: ["$passed", 1, 0] } },
        total: { $sum: 1 },
        annulled: { $sum: { $cond: [{ $eq: ["$status", "annulled"] }, 1, 0] } },
        incidents: { $sum: "$incidents" }
      }
    }
  ])
  .toArray()[0] || {
    averageScore: 0,
    approved: 0,
    total: 0,
    annulled: 0,
    incidents: 0
  };

printjson(
  db.teacher_metric_snapshots.insertOne({
    _id: `snapshot_manual_${Date.now()}`,
    runId: "manual_update",
    refreshedAt: new Date(),
    summary: {
      totalStudents,
      activeStudents,
      completedMissions: 0,
      trainingAttempts,
      trainingAccuracy: Math.round((trainingCorrect / Math.max(trainingAttempts, 1)) * 100),
      averageAssessmentScore: Math.round(assessmentSummary.averageScore || 0),
      approvalRate: Math.round((assessmentSummary.approved / Math.max(assessmentSummary.total, 1)) * 100),
      incidents: assessmentSummary.incidents,
      annulledAttempts: assessmentSummary.annulled
    },
    studentEvolution: [],
    academicPerformance: [],
    topicDifficulty: [],
    integrity: []
  })
);

print("\n9) Indices existentes");
printjson({
  students: db.students.getIndexes(),
  learning_catalog: db.learning_catalog.getIndexes(),
  training_attempts: db.training_attempts.getIndexes(),
  assessment_attempts: db.assessment_attempts.getIndexes(),
  integrity_events: db.integrity_events.getIndexes(),
  teacher_metric_snapshots: db.teacher_metric_snapshots.getIndexes()
});
