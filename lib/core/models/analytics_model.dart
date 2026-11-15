class AnalyticsDashboard {
  const AnalyticsDashboard({
    required this.refreshedAt,
    required this.summary,
    required this.studentEvolution,
    required this.academicPerformance,
    required this.topicDifficulty,
    required this.integrity,
  });

  final DateTime? refreshedAt;
  final AnalyticsKpiSummary summary;
  final List<StudentEvolutionMetric> studentEvolution;
  final List<AcademicPerformanceMetric> academicPerformance;
  final List<TopicDifficultyMetric> topicDifficulty;
  final List<IntegrityMetric> integrity;

  factory AnalyticsDashboard.fromJson(Map<String, Object?> json) =>
      AnalyticsDashboard(
        refreshedAt: json.optionalString('refreshedAt') == null
            ? null
            : DateTime.parse(json.text('refreshedAt')),
        summary: AnalyticsKpiSummary.fromJson(json.object('summary')),
        studentEvolution: json
            .objects('studentEvolution')
            .map(StudentEvolutionMetric.fromJson)
            .toList(),
        academicPerformance: json
            .objects('academicPerformance')
            .map(AcademicPerformanceMetric.fromJson)
            .toList(),
        topicDifficulty: json
            .objects('topicDifficulty')
            .map(TopicDifficultyMetric.fromJson)
            .toList(),
        integrity: json
            .objects('integrity')
            .map(IntegrityMetric.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    'refreshedAt': refreshedAt?.toUtc().toIso8601String(),
    'summary': summary.toJson(),
    'studentEvolution': studentEvolution.map((item) => item.toJson()).toList(),
    'academicPerformance': academicPerformance
        .map((item) => item.toJson())
        .toList(),
    'topicDifficulty': topicDifficulty.map((item) => item.toJson()).toList(),
    'integrity': integrity.map((item) => item.toJson()).toList(),
  };
}

class AnalyticsKpiSummary {
  const AnalyticsKpiSummary({
    required this.totalStudents,
    required this.activeStudents,
    required this.completedMissions,
    required this.trainingAttempts,
    required this.trainingAccuracy,
    required this.averageAssessmentScore,
    required this.approvalRate,
    required this.incidents,
    required this.annulledAttempts,
  });

  final int totalStudents;
  final int activeStudents;
  final int completedMissions;
  final int trainingAttempts;
  final int trainingAccuracy;
  final int averageAssessmentScore;
  final int approvalRate;
  final int incidents;
  final int annulledAttempts;

  factory AnalyticsKpiSummary.fromJson(Map<String, Object?> json) =>
      AnalyticsKpiSummary(
        totalStudents: json.integer('totalStudents'),
        activeStudents: json.integer('activeStudents'),
        completedMissions: json.integer('completedMissions'),
        trainingAttempts: json.integer('trainingAttempts'),
        trainingAccuracy: json.integer('trainingAccuracy'),
        averageAssessmentScore: json.integer('averageAssessmentScore'),
        approvalRate: json.integer('approvalRate'),
        incidents: json.integer('incidents'),
        annulledAttempts: json.integer('annulledAttempts'),
      );

  Map<String, Object?> toJson() => {
    'totalStudents': totalStudents,
    'activeStudents': activeStudents,
    'completedMissions': completedMissions,
    'trainingAttempts': trainingAttempts,
    'trainingAccuracy': trainingAccuracy,
    'averageAssessmentScore': averageAssessmentScore,
    'approvalRate': approvalRate,
    'incidents': incidents,
    'annulledAttempts': annulledAttempts,
  };
}

class StudentEvolutionMetric {
  const StudentEvolutionMetric({
    required this.studentId,
    required this.studentName,
    required this.activeDays,
    required this.completedMissions,
    required this.totalMissions,
    required this.trainingAccuracy,
    required this.recentTrainingAccuracy,
    required this.bestAssessmentScore,
    required this.latestAssessmentScore,
    this.firstActivityAt,
  });

  final String studentId;
  final String studentName;
  final DateTime? firstActivityAt;
  final int activeDays;
  final int completedMissions;
  final int totalMissions;
  final int trainingAccuracy;
  final int recentTrainingAccuracy;
  final int bestAssessmentScore;
  final int latestAssessmentScore;

  factory StudentEvolutionMetric.fromJson(Map<String, Object?> json) =>
      StudentEvolutionMetric(
        studentId: json.text('studentId'),
        studentName: json.text('studentName'),
        firstActivityAt: json.optionalString('firstActivityAt') == null
            ? null
            : DateTime.parse(json.text('firstActivityAt')),
        activeDays: json.integer('activeDays'),
        completedMissions: json.integer('completedMissions'),
        totalMissions: json.integer('totalMissions'),
        trainingAccuracy: json.integer('trainingAccuracy'),
        recentTrainingAccuracy: json.integer('recentTrainingAccuracy'),
        bestAssessmentScore: json.integer('bestAssessmentScore'),
        latestAssessmentScore: json.integer('latestAssessmentScore'),
      );

  Map<String, Object?> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'firstActivityAt': firstActivityAt?.toUtc().toIso8601String(),
    'activeDays': activeDays,
    'completedMissions': completedMissions,
    'totalMissions': totalMissions,
    'trainingAccuracy': trainingAccuracy,
    'recentTrainingAccuracy': recentTrainingAccuracy,
    'bestAssessmentScore': bestAssessmentScore,
    'latestAssessmentScore': latestAssessmentScore,
  };
}

class AcademicPerformanceMetric {
  const AcademicPerformanceMetric({
    required this.studentId,
    required this.studentName,
    required this.averageScore,
    required this.approvedAttempts,
    required this.totalAttempts,
    required this.trainingAccuracy,
    required this.trainingAssessmentGap,
  });

  final String studentId;
  final String studentName;
  final int averageScore;
  final int approvedAttempts;
  final int totalAttempts;
  final int trainingAccuracy;
  final int trainingAssessmentGap;

  factory AcademicPerformanceMetric.fromJson(Map<String, Object?> json) =>
      AcademicPerformanceMetric(
        studentId: json.text('studentId'),
        studentName: json.text('studentName'),
        averageScore: json.integer('averageScore'),
        approvedAttempts: json.integer('approvedAttempts'),
        totalAttempts: json.integer('totalAttempts'),
        trainingAccuracy: json.integer('trainingAccuracy'),
        trainingAssessmentGap: json.integer('trainingAssessmentGap'),
      );

  Map<String, Object?> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'averageScore': averageScore,
    'approvedAttempts': approvedAttempts,
    'totalAttempts': totalAttempts,
    'trainingAccuracy': trainingAccuracy,
    'trainingAssessmentGap': trainingAssessmentGap,
  };
}

class TopicDifficultyMetric {
  const TopicDifficultyMetric({
    required this.topicId,
    required this.topicTitle,
    required this.worldTitle,
    required this.trainingAccuracy,
    required this.assessmentScore,
    required this.attempts,
  });

  final String topicId;
  final String topicTitle;
  final String worldTitle;
  final int trainingAccuracy;
  final int assessmentScore;
  final int attempts;

  factory TopicDifficultyMetric.fromJson(Map<String, Object?> json) =>
      TopicDifficultyMetric(
        topicId: json.text('topicId'),
        topicTitle: json.text('topicTitle'),
        worldTitle: json.text('worldTitle'),
        trainingAccuracy: json.integer('trainingAccuracy'),
        assessmentScore: json.integer('assessmentScore'),
        attempts: json.integer('attempts'),
      );

  Map<String, Object?> toJson() => {
    'topicId': topicId,
    'topicTitle': topicTitle,
    'worldTitle': worldTitle,
    'trainingAccuracy': trainingAccuracy,
    'assessmentScore': assessmentScore,
    'attempts': attempts,
  };
}

class IntegrityMetric {
  const IntegrityMetric({
    required this.studentId,
    required this.studentName,
    required this.incidents,
    required this.annulledAttempts,
    required this.reactivations,
    required this.riskLevel,
  });

  final String studentId;
  final String studentName;
  final int incidents;
  final int annulledAttempts;
  final int reactivations;
  final String riskLevel;

  factory IntegrityMetric.fromJson(Map<String, Object?> json) =>
      IntegrityMetric(
        studentId: json.text('studentId'),
        studentName: json.text('studentName'),
        incidents: json.integer('incidents'),
        annulledAttempts: json.integer('annulledAttempts'),
        reactivations: json.integer('reactivations'),
        riskLevel: json.text('riskLevel'),
      );

  Map<String, Object?> toJson() => {
    'studentId': studentId,
    'studentName': studentName,
    'incidents': incidents,
    'annulledAttempts': annulledAttempts,
    'reactivations': reactivations,
    'riskLevel': riskLevel,
  };
}

extension AnalyticsJsonReader on Map<String, Object?> {
  Map<String, Object?> object(String key) {
    final value = this[key];
    if (value is Map<String, Object?>) return value;
    throw FormatException('"$key" debe ser objeto.');
  }

  List<Map<String, Object?>> objects(String key) {
    final value = this[key];
    if (value is! List<Object?>) {
      throw FormatException('"$key" debe ser lista.');
    }
    return value.map((item) {
      if (item is Map<String, Object?>) return item;
      throw FormatException('Los elementos de "$key" deben ser objetos.');
    }).toList();
  }

  String text(String key) {
    final value = this[key];
    if (value is String) return value;
    throw FormatException('"$key" debe ser texto.');
  }

  String? optionalString(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('"$key" debe ser texto.');
  }

  int integer(String key) {
    final value = this[key];
    if (value is int) return value;
    throw FormatException('"$key" debe ser entero.');
  }
}
