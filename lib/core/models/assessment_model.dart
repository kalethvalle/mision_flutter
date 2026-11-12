import 'authoring_model.dart';

enum AssessmentAttemptStatus {
  open('open'),
  submitted('submitted'),
  annulled('annulled');

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
    this.activeSessionId,
    this.sessionClosesAt,
    this.durationMinutes,
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
  final String? activeSessionId;
  final DateTime? sessionClosesAt;
  final int? durationMinutes;
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
        activeSessionId: json.optionalString('activeSessionId'),
        sessionClosesAt: json.optionalString('sessionClosesAt') == null
            ? null
            : DateTime.parse(json.text('sessionClosesAt')),
        durationMinutes: json.optionalInteger('durationMinutes'),
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
    'activeSessionId': activeSessionId,
    'sessionClosesAt': sessionClosesAt?.toUtc().toIso8601String(),
    'durationMinutes': durationMinutes,
    'openAttemptId': openAttemptId,
  };
}

class AssessmentWorldSettings {
  const AssessmentWorldSettings({
    required this.worldId,
    required this.durationMinutes,
    required this.fullscreenRequired,
    required this.maxIncidents,
    required this.returnGraceSeconds,
    required this.strictMode,
  });

  final String worldId;
  final int durationMinutes;
  final bool fullscreenRequired;
  final int maxIncidents;
  final int returnGraceSeconds;
  final bool strictMode;

  factory AssessmentWorldSettings.defaults(String worldId) =>
      AssessmentWorldSettings(
        worldId: worldId,
        durationMinutes: 20,
        fullscreenRequired: true,
        maxIncidents: 2,
        returnGraceSeconds: 10,
        strictMode: true,
      );

  factory AssessmentWorldSettings.fromJson(Map<String, Object?> json) =>
      AssessmentWorldSettings(
        worldId: json.text('worldId'),
        durationMinutes: json.integer('durationMinutes'),
        fullscreenRequired: json.boolean('fullscreenRequired'),
        maxIncidents: json.integer('maxIncidents'),
        returnGraceSeconds: json.integer('returnGraceSeconds'),
        strictMode: json.boolean('strictMode'),
      );

  Map<String, Object?> toJson() => {
    'worldId': worldId,
    'durationMinutes': durationMinutes,
    'fullscreenRequired': fullscreenRequired,
    'maxIncidents': maxIncidents,
    'returnGraceSeconds': returnGraceSeconds,
    'strictMode': strictMode,
  };
}

enum AssessmentSessionStatus {
  open('open'),
  closed('closed');

  const AssessmentSessionStatus(this.wireName);
  final String wireName;

  static AssessmentSessionStatus fromWireName(String value) =>
      values.firstWhere(
        (status) => status.wireName == value,
        orElse: () =>
            throw FormatException('Estado de sesión inválido: $value'),
      );
}

class AssessmentLiveAttempt {
  const AssessmentLiveAttempt({
    required this.attemptId,
    required this.userId,
    required this.studentName,
    required this.status,
    required this.startedAt,
    required this.deadlineAt,
    required this.answeredQuestions,
    required this.totalQuestions,
    required this.incidents,
    required this.reactivationCount,
    this.submittedAt,
    this.score,
    this.annulledReason,
  });

  final String attemptId;
  final String userId;
  final String studentName;
  final AssessmentAttemptStatus status;
  final DateTime startedAt;
  final DateTime deadlineAt;
  final int answeredQuestions;
  final int totalQuestions;
  final int incidents;
  final int reactivationCount;
  final DateTime? submittedAt;
  final int? score;
  final String? annulledReason;

  factory AssessmentLiveAttempt.fromJson(Map<String, Object?> json) =>
      AssessmentLiveAttempt(
        attemptId: json.text('attemptId'),
        userId: json.text('userId'),
        studentName: json.text('studentName'),
        status: AssessmentAttemptStatus.fromWireName(json.text('status')),
        startedAt: DateTime.parse(json.text('startedAt')),
        deadlineAt: DateTime.parse(json.text('deadlineAt')),
        answeredQuestions: json.integer('answeredQuestions'),
        totalQuestions: json.integer('totalQuestions'),
        incidents: json.integer('incidents'),
        reactivationCount: json.integer('reactivationCount'),
        submittedAt: json.optionalString('submittedAt') == null
            ? null
            : DateTime.parse(json.text('submittedAt')),
        score: json.optionalInteger('score'),
        annulledReason: json.optionalString('annulledReason'),
      );

  Map<String, Object?> toJson() => {
    'attemptId': attemptId,
    'userId': userId,
    'studentName': studentName,
    'status': status.wireName,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'deadlineAt': deadlineAt.toUtc().toIso8601String(),
    'answeredQuestions': answeredQuestions,
    'totalQuestions': totalQuestions,
    'incidents': incidents,
    'reactivationCount': reactivationCount,
    'submittedAt': submittedAt?.toUtc().toIso8601String(),
    'score': score,
    'annulledReason': annulledReason,
  };
}

class AssessmentSession {
  const AssessmentSession({
    required this.id,
    required this.worldId,
    required this.worldTitle,
    required this.status,
    required this.openedAt,
    required this.closesAt,
    required this.durationMinutes,
    required this.settings,
    required this.attempts,
    this.closedAt,
  });

  final String id;
  final String worldId;
  final String worldTitle;
  final AssessmentSessionStatus status;
  final DateTime openedAt;
  final DateTime closesAt;
  final DateTime? closedAt;
  final int durationMinutes;
  final AssessmentWorldSettings settings;
  final List<AssessmentLiveAttempt> attempts;

  factory AssessmentSession.fromJson(Map<String, Object?> json) =>
      AssessmentSession(
        id: json.text('id'),
        worldId: json.text('worldId'),
        worldTitle: json.text('worldTitle'),
        status: AssessmentSessionStatus.fromWireName(json.text('status')),
        openedAt: DateTime.parse(json.text('openedAt')),
        closesAt: DateTime.parse(json.text('closesAt')),
        closedAt: json.optionalString('closedAt') == null
            ? null
            : DateTime.parse(json.text('closedAt')),
        durationMinutes: json.integer('durationMinutes'),
        settings: AssessmentWorldSettings.fromJson(json.object('settings')),
        attempts: json
            .objects('attempts')
            .map(AssessmentLiveAttempt.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'worldId': worldId,
    'worldTitle': worldTitle,
    'status': status.wireName,
    'openedAt': openedAt.toUtc().toIso8601String(),
    'closesAt': closesAt.toUtc().toIso8601String(),
    'closedAt': closedAt?.toUtc().toIso8601String(),
    'durationMinutes': durationMinutes,
    'settings': settings.toJson(),
    'attempts': attempts.map((attempt) => attempt.toJson()).toList(),
  };
}

class AssessmentSessionOverview {
  const AssessmentSessionOverview({
    required this.settings,
    required this.sessions,
  });

  final List<AssessmentWorldSettings> settings;
  final List<AssessmentSession> sessions;

  factory AssessmentSessionOverview.fromJson(Map<String, Object?> json) =>
      AssessmentSessionOverview(
        settings: json
            .objects('settings')
            .map(AssessmentWorldSettings.fromJson)
            .toList(),
        sessions: json
            .objects('sessions')
            .map(AssessmentSession.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    'settings': settings.map((item) => item.toJson()).toList(),
    'sessions': sessions.map((item) => item.toJson()).toList(),
  };
}

class AssessmentAttemptEvent {
  const AssessmentAttemptEvent({
    required this.id,
    required this.sessionId,
    required this.attemptId,
    required this.type,
    required this.message,
    required this.occurredAt,
    this.userId,
    this.studentName,
    this.answeredQuestions,
    this.totalQuestions,
    this.score,
  });

  final String id;
  final String sessionId;
  final String? attemptId;
  final String? userId;
  final String? studentName;
  final String type;
  final String message;
  final DateTime occurredAt;
  final int? answeredQuestions;
  final int? totalQuestions;
  final int? score;

  factory AssessmentAttemptEvent.fromJson(Map<String, Object?> json) =>
      AssessmentAttemptEvent(
        id: json.text('id'),
        sessionId: json.text('sessionId'),
        attemptId: json.optionalString('attemptId'),
        userId: json.optionalString('userId'),
        studentName: json.optionalString('studentName'),
        type: json.text('type'),
        message: json.text('message'),
        occurredAt: DateTime.parse(json.text('occurredAt')),
        answeredQuestions: json.optionalInteger('answeredQuestions'),
        totalQuestions: json.optionalInteger('totalQuestions'),
        score: json.optionalInteger('score'),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'sessionId': sessionId,
    'attemptId': attemptId,
    'userId': userId,
    'studentName': studentName,
    'type': type,
    'message': message,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'answeredQuestions': answeredQuestions,
    'totalQuestions': totalQuestions,
    'score': score,
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
    required this.deadlineAt,
    required this.settings,
    required this.draftAnswers,
    required this.questions,
  });

  final String id;
  final String worldId;
  final String worldTitle;
  final DateTime startedAt;
  final DateTime deadlineAt;
  final AssessmentWorldSettings settings;
  final Map<String, List<String>> draftAnswers;
  final List<AssessmentQuestion> questions;

  factory AssessmentAttempt.fromJson(Map<String, Object?> json) =>
      AssessmentAttempt(
        id: json.text('id'),
        worldId: json.text('worldId'),
        worldTitle: json.text('worldTitle'),
        startedAt: DateTime.parse(json.text('startedAt')),
        deadlineAt: DateTime.parse(json.text('deadlineAt')),
        settings: AssessmentWorldSettings.fromJson(json.object('settings')),
        draftAnswers: {
          for (final raw in json.objects('draftAnswers'))
            raw.text('questionId'): raw.textList('optionIds'),
        },
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
    'deadlineAt': deadlineAt.toUtc().toIso8601String(),
    'settings': settings.toJson(),
    'draftAnswers': draftAnswers.entries
        .map((entry) => {'questionId': entry.key, 'optionIds': entry.value})
        .toList(),
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
    required this.status,
    required this.startedAt,
    required this.deadlineAt,
    required this.submittedAt,
    required this.durationSeconds,
    required this.incidents,
    required this.reactivationCount,
    required this.topics,
  });

  final String id;
  final String userId;
  final String studentName;
  final String worldId;
  final String worldTitle;
  final int score;
  final bool passed;
  final AssessmentAttemptStatus status;
  final DateTime startedAt;
  final DateTime deadlineAt;
  final DateTime? submittedAt;
  final int durationSeconds;
  final int incidents;
  final int reactivationCount;
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
        status: AssessmentAttemptStatus.fromWireName(json.text('status')),
        startedAt: DateTime.parse(json.text('startedAt')),
        deadlineAt: DateTime.parse(json.text('deadlineAt')),
        submittedAt: json.optionalString('submittedAt') == null
            ? null
            : DateTime.parse(json.text('submittedAt')),
        durationSeconds: json.integer('durationSeconds'),
        incidents: json.integer('incidents'),
        reactivationCount: json.integer('reactivationCount'),
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
    'status': status.wireName,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'deadlineAt': deadlineAt.toUtc().toIso8601String(),
    'submittedAt': submittedAt?.toUtc().toIso8601String(),
    'durationSeconds': durationSeconds,
    'incidents': incidents,
    'reactivationCount': reactivationCount,
    'topics': topics.map((topic) => topic.toJson()).toList(),
  };
}

class AssessmentQuestionReport {
  const AssessmentQuestionReport({
    required this.number,
    required this.topicTitle,
    required this.prompt,
    required this.selectedOptionTexts,
    required this.correctOptionTexts,
    required this.isCorrect,
    required this.points,
    required this.explanation,
  });

  final int number;
  final String topicTitle;
  final String prompt;
  final List<String> selectedOptionTexts;
  final List<String> correctOptionTexts;
  final bool isCorrect;
  final int points;
  final String explanation;

  factory AssessmentQuestionReport.fromJson(Map<String, Object?> json) =>
      AssessmentQuestionReport(
        number: json.integer('number'),
        topicTitle: json.text('topicTitle'),
        prompt: json.text('prompt'),
        selectedOptionTexts: json.textList('selectedOptionTexts'),
        correctOptionTexts: json.textList('correctOptionTexts'),
        isCorrect: json.boolean('isCorrect'),
        points: json.integer('points'),
        explanation: json.text('explanation'),
      );

  Map<String, Object?> toJson() => {
    'number': number,
    'topicTitle': topicTitle,
    'prompt': prompt,
    'selectedOptionTexts': selectedOptionTexts,
    'correctOptionTexts': correctOptionTexts,
    'isCorrect': isCorrect,
    'points': points,
    'explanation': explanation,
  };
}

class AssessmentDetailReport {
  const AssessmentDetailReport({
    required this.attempt,
    required this.questions,
    required this.events,
  });

  final AssessmentReportItem attempt;
  final List<AssessmentQuestionReport> questions;
  final List<AssessmentAttemptEvent> events;

  factory AssessmentDetailReport.fromJson(Map<String, Object?> json) =>
      AssessmentDetailReport(
        attempt: AssessmentReportItem.fromJson(json.object('attempt')),
        questions: json
            .objects('questions')
            .map(AssessmentQuestionReport.fromJson)
            .toList(),
        events: json
            .objects('events')
            .map(AssessmentAttemptEvent.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    'attempt': attempt.toJson(),
    'questions': questions.map((item) => item.toJson()).toList(),
    'events': events.map((event) => event.toJson()).toList(),
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
  Map<String, Object?> object(String key) {
    final value = this[key];
    if (value is Map<String, Object?>) return value;
    throw FormatException('"$key" debe ser objeto.');
  }

  int? optionalInteger(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is! int) throw FormatException('"$key" debe ser entero.');
    return value;
  }
}
