import 'authoring_model.dart';

enum AssessmentAttemptStatus {
  open('open'),
  submitted('submitted');

  const AssessmentAttemptStatus(this.wireName);
  final String wireName;

  static AssessmentAttemptStatus fromWireName(String value) =>
      values.firstWhere(
        (status) => status.wireName == value,
        orElse: () =>
            throw FormatException('Estado de intento inválido: $value'),
      );
}

class AssessmentAvailability {
  const AssessmentAvailability({
    required this.worldId,
    required this.worldTitle,
    required this.isAvailable,
    required this.reason,
    required this.publishedQuestions,
    required this.completedMissions,
    required this.totalMissions,
    required this.completedAttempts,
    required this.bestScore,
    this.openAttemptId,
  });

  final String worldId;
  final String worldTitle;
  final bool isAvailable;
  final String? reason;
  final int publishedQuestions;
  final int completedMissions;
  final int totalMissions;
  final int completedAttempts;
  final int? bestScore;
  final String? openAttemptId;

  factory AssessmentAvailability.fromJson(Map<String, Object?> json) =>
      AssessmentAvailability(
        worldId: json.text('worldId'),
        worldTitle: json.text('worldTitle'),
        isAvailable: json.boolean('isAvailable'),
        reason: json.optionalString('reason'),
        publishedQuestions: json.integer('publishedQuestions'),
        completedMissions: json.integer('completedMissions'),
        totalMissions: json.integer('totalMissions'),
        completedAttempts: json.integer('completedAttempts'),
        bestScore: json.optionalInteger('bestScore'),
        openAttemptId: json.optionalString('openAttemptId'),
      );

  Map<String, Object?> toJson() => {
    'worldId': worldId,
    'worldTitle': worldTitle,
    'isAvailable': isAvailable,
    'reason': reason,
    'publishedQuestions': publishedQuestions,
    'completedMissions': completedMissions,
    'totalMissions': totalMissions,
    'completedAttempts': completedAttempts,
    'bestScore': bestScore,
    'openAttemptId': openAttemptId,
  };
}

class AssessmentHistoryItem {
  const AssessmentHistoryItem({
    required this.id,
    required this.worldId,
    required this.worldTitle,
    required this.startedAt,
    required this.submittedAt,
    required this.score,
    required this.passed,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  final String id;
  final String worldId;
  final String worldTitle;
  final DateTime startedAt;
  final DateTime submittedAt;
  final int score;
  final bool passed;
  final int correctAnswers;
  final int totalQuestions;

  factory AssessmentHistoryItem.fromJson(Map<String, Object?> json) =>
      AssessmentHistoryItem(
        id: json.text('id'),
        worldId: json.text('worldId'),
        worldTitle: json.text('worldTitle'),
        startedAt: DateTime.parse(json.text('startedAt')),
        submittedAt: DateTime.parse(json.text('submittedAt')),
        score: json.integer('score'),
        passed: json.boolean('passed'),
        correctAnswers: json.integer('correctAnswers'),
        totalQuestions: json.integer('totalQuestions'),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'worldId': worldId,
    'worldTitle': worldTitle,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'submittedAt': submittedAt.toUtc().toIso8601String(),
    'score': score,
    'passed': passed,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
  };
}

class AssessmentOverview {
  const AssessmentOverview({required this.availability, required this.history});

  final List<AssessmentAvailability> availability;
  final List<AssessmentHistoryItem> history;

  factory AssessmentOverview.fromJson(Map<String, Object?> json) =>
      AssessmentOverview(
        availability: json
            .objects('availability')
            .map(AssessmentAvailability.fromJson)
            .toList(),
        history: json
            .objects('history')
            .map(AssessmentHistoryItem.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    'availability': availability.map((item) => item.toJson()).toList(),
    'history': history.map((item) => item.toJson()).toList(),
  };
}

class AssessmentOption {
  const AssessmentOption({required this.id, required this.text});
  final String id;
  final String text;

  factory AssessmentOption.fromJson(Map<String, Object?> json) =>
      AssessmentOption(id: json.text('id'), text: json.text('text'));

  Map<String, Object?> toJson() => {'id': id, 'text': text};
}

class AssessmentQuestion {
  const AssessmentQuestion({
    required this.id,
    required this.topicId,
    required this.topicTitle,
    required this.prompt,
    required this.type,
    required this.contentVersion,
    required this.options,
  });

  final String id;
  final String topicId;
  final String topicTitle;
  final String prompt;
  final QuestionType type;
  final int contentVersion;
  final List<AssessmentOption> options;

  factory AssessmentQuestion.fromJson(Map<String, Object?> json) =>
      AssessmentQuestion(
        id: json.text('id'),
        topicId: json.text('topicId'),
        topicTitle: json.text('topicTitle'),
        prompt: json.text('prompt'),
        type: QuestionType.fromWireName(json.text('type')),
        contentVersion: json.integer('contentVersion'),
        options: json
            .objects('options')
            .map(AssessmentOption.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'topicId': topicId,
    'topicTitle': topicTitle,
    'prompt': prompt,
    'type': type.wireName,
    'contentVersion': contentVersion,
    'options': options.map((option) => option.toJson()).toList(),
  };
}

class AssessmentAttempt {
  const AssessmentAttempt({
    required this.id,
    required this.worldId,
    required this.worldTitle,
    required this.startedAt,
    required this.questions,
  });

  final String id;
  final String worldId;
  final String worldTitle;
  final DateTime startedAt;
  final List<AssessmentQuestion> questions;

  factory AssessmentAttempt.fromJson(Map<String, Object?> json) =>
      AssessmentAttempt(
        id: json.text('id'),
        worldId: json.text('worldId'),
        worldTitle: json.text('worldTitle'),
        startedAt: DateTime.parse(json.text('startedAt')),
        questions: json
            .objects('questions')
            .map(AssessmentQuestion.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'worldId': worldId,
    'worldTitle': worldTitle,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'questions': questions.map((question) => question.toJson()).toList(),
  };
}

class TopicAssessmentScore {
  const TopicAssessmentScore({
    required this.topicId,
    required this.topicTitle,
    required this.correctAnswers,
    required this.totalQuestions,
  });

  final String topicId;
  final String topicTitle;
  final int correctAnswers;
  final int totalQuestions;
  int get score =>
      totalQuestions == 0 ? 0 : (100 * correctAnswers / totalQuestions).round();

  factory TopicAssessmentScore.fromJson(Map<String, Object?> json) =>
      TopicAssessmentScore(
        topicId: json.text('topicId'),
        topicTitle: json.text('topicTitle'),
        correctAnswers: json.integer('correctAnswers'),
        totalQuestions: json.integer('totalQuestions'),
      );

  Map<String, Object?> toJson() => {
    'topicId': topicId,
    'topicTitle': topicTitle,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'score': score,
  };
}

class AssessmentReview {
  const AssessmentReview({
    required this.questionId,
    required this.topicId,
    required this.prompt,
    required this.type,
    required this.selectedOptionIds,
    required this.correctOptionIds,
    required this.options,
    required this.explanation,
    required this.isCorrect,
  });

  final String questionId;
  final String topicId;
  final String prompt;
  final QuestionType type;
  final List<String> selectedOptionIds;
  final List<String> correctOptionIds;
  final List<AssessmentOption> options;
  final String explanation;
  final bool isCorrect;

  factory AssessmentReview.fromJson(Map<String, Object?> json) =>
      AssessmentReview(
        questionId: json.text('questionId'),
        topicId: json.text('topicId'),
        prompt: json.text('prompt'),
        type: QuestionType.fromWireName(json.text('type')),
        selectedOptionIds: json.textList('selectedOptionIds'),
        correctOptionIds: json.textList('correctOptionIds'),
        options: json
            .objects('options')
            .map(AssessmentOption.fromJson)
            .toList(),
        explanation: json.text('explanation'),
        isCorrect: json.boolean('isCorrect'),
      );

  Map<String, Object?> toJson() => {
    'questionId': questionId,
    'topicId': topicId,
    'prompt': prompt,
    'type': type.wireName,
    'selectedOptionIds': selectedOptionIds,
    'correctOptionIds': correctOptionIds,
    'options': options.map((option) => option.toJson()).toList(),
    'explanation': explanation,
    'isCorrect': isCorrect,
  };
}

class AssessmentResult {
  const AssessmentResult({
    required this.attemptId,
    required this.worldId,
    required this.worldTitle,
    required this.score,
    required this.passed,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.submittedAt,
    required this.topics,
    required this.reviews,
  });

  final String attemptId;
  final String worldId;
  final String worldTitle;
  final int score;
  final bool passed;
  final int correctAnswers;
  final int totalQuestions;
  final DateTime submittedAt;
  final List<TopicAssessmentScore> topics;
  final List<AssessmentReview> reviews;

  factory AssessmentResult.fromJson(
    Map<String, Object?> json,
  ) => AssessmentResult(
    attemptId: json.text('attemptId'),
    worldId: json.text('worldId'),
    worldTitle: json.text('worldTitle'),
    score: json.integer('score'),
    passed: json.boolean('passed'),
    correctAnswers: json.integer('correctAnswers'),
    totalQuestions: json.integer('totalQuestions'),
    submittedAt: DateTime.parse(json.text('submittedAt')),
    topics: json.objects('topics').map(TopicAssessmentScore.fromJson).toList(),
    reviews: json.objects('reviews').map(AssessmentReview.fromJson).toList(),
  );

  Map<String, Object?> toJson() => {
    'attemptId': attemptId,
    'worldId': worldId,
    'worldTitle': worldTitle,
    'score': score,
    'passed': passed,
    'correctAnswers': correctAnswers,
    'totalQuestions': totalQuestions,
    'submittedAt': submittedAt.toUtc().toIso8601String(),
    'topics': topics.map((topic) => topic.toJson()).toList(),
    'reviews': reviews.map((review) => review.toJson()).toList(),
  };
}

class TrainingReportItem {
  const TrainingReportItem({
    required this.id,
    required this.userId,
    required this.studentName,
    required this.worldId,
    required this.worldTitle,
    required this.topicId,
    required this.topicTitle,
    required this.missionTitle,
    required this.isCorrect,
    required this.hintUsed,
    required this.occurredAt,
  });

  final String id;
  final String userId;
  final String studentName;
  final String worldId;
  final String worldTitle;
  final String topicId;
  final String topicTitle;
  final String missionTitle;
  final bool isCorrect;
  final bool hintUsed;
  final DateTime occurredAt;

  factory TrainingReportItem.fromJson(Map<String, Object?> json) =>
      TrainingReportItem(
        id: json.text('id'),
        userId: json.text('userId'),
        studentName: json.text('studentName'),
        worldId: json.text('worldId'),
        worldTitle: json.text('worldTitle'),
        topicId: json.text('topicId'),
        topicTitle: json.text('topicTitle'),
        missionTitle: json.text('missionTitle'),
        isCorrect: json.boolean('isCorrect'),
        hintUsed: json.boolean('hintUsed'),
        occurredAt: DateTime.parse(json.text('occurredAt')),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'studentName': studentName,
    'worldId': worldId,
    'worldTitle': worldTitle,
    'topicId': topicId,
    'topicTitle': topicTitle,
    'missionTitle': missionTitle,
    'isCorrect': isCorrect,
    'hintUsed': hintUsed,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
  };
}

class AssessmentReportItem {
  const AssessmentReportItem({
    required this.id,
    required this.userId,
    required this.studentName,
    required this.worldId,
    required this.worldTitle,
    required this.score,
    required this.passed,
    required this.submittedAt,
    required this.topics,
  });

  final String id;
  final String userId;
  final String studentName;
  final String worldId;
  final String worldTitle;
  final int score;
  final bool passed;
  final DateTime submittedAt;
  final List<TopicAssessmentScore> topics;

  factory AssessmentReportItem.fromJson(Map<String, Object?> json) =>
      AssessmentReportItem(
        id: json.text('id'),
        userId: json.text('userId'),
        studentName: json.text('studentName'),
        worldId: json.text('worldId'),
        worldTitle: json.text('worldTitle'),
        score: json.integer('score'),
        passed: json.boolean('passed'),
        submittedAt: DateTime.parse(json.text('submittedAt')),
        topics: json
            .objects('topics')
            .map(TopicAssessmentScore.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'userId': userId,
    'studentName': studentName,
    'worldId': worldId,
    'worldTitle': worldTitle,
    'score': score,
    'passed': passed,
    'submittedAt': submittedAt.toUtc().toIso8601String(),
    'topics': topics.map((topic) => topic.toJson()).toList(),
  };
}

class TeacherReport {
  const TeacherReport({required this.training, required this.assessments});
  final List<TrainingReportItem> training;
  final List<AssessmentReportItem> assessments;

  factory TeacherReport.fromJson(Map<String, Object?> json) => TeacherReport(
    training: json
        .objects('training')
        .map(TrainingReportItem.fromJson)
        .toList(),
    assessments: json
        .objects('assessments')
        .map(AssessmentReportItem.fromJson)
        .toList(),
  );

  Map<String, Object?> toJson() => {
    'training': training.map((item) => item.toJson()).toList(),
    'assessments': assessments.map((item) => item.toJson()).toList(),
  };
}

extension AssessmentJsonReader on Map<String, Object?> {
  int? optionalInteger(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is! int) throw FormatException('"$key" debe ser entero.');
    return value;
  }
}
