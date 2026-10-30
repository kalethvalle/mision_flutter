import 'mission_model.dart';
import 'progress_model.dart';

class AnswerCheckResult {
  const AnswerCheckResult({
    required this.missionId,
    required this.isCorrect,
    required this.message,
    this.progress,
  });

  final String missionId;
  final bool isCorrect;
  final String message;
  final StudentProgress? progress;

  factory AnswerCheckResult.fromJson(Map<String, Object?> json) {
    final isCorrect = json['isCorrect'];
    if (isCorrect is! bool) {
      throw const FormatException('El campo "isCorrect" debe ser booleano.');
    }
    return AnswerCheckResult(
      missionId: json.string('missionId'),
      isCorrect: isCorrect,
      message: json.string('message'),
      progress: json['progress'] == null
          ? null
          : StudentProgress.fromJson(json['progress']! as Map<String, Object?>),
    );
  }

  Map<String, Object?> toJson() => {
    'missionId': missionId,
    'isCorrect': isCorrect,
    'message': message,
    'progress': progress?.toJson(),
  };
}
