import '../../core/models/answer_check_result.dart';
import '../../core/models/progress_model.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/catalog_repository.dart';

abstract interface class ProgressStore {
  Future<StudentProgress> loadProgress(String userId);
}

abstract interface class TrainingStore {
  Future<AnswerCheckResult> checkAndRecord({
    required String userId,
    required String missionId,
    required List<String> optionIds,
    required bool hintUsed,
  });
}

class ProgressService {
  const ProgressService(this._progressStore, this._trainingStore);

  final ProgressStore _progressStore;
  final TrainingStore _trainingStore;

  Future<StudentProgress> load(UserModel user) {
    _requireStudent(user);
    return _progressStore.loadProgress(user.id);
  }

  Future<AnswerCheckResult> checkAnswer({
    required UserModel user,
    required String missionId,
    required List<String> optionIds,
    required bool hintUsed,
  }) {
    _requireStudent(user);
    final selected = optionIds
        .map((optionId) => optionId.trim())
        .where((optionId) => optionId.isNotEmpty)
        .toSet();
    if (missionId.trim().isEmpty || selected.isEmpty) {
      throw const CatalogException(
        'invalid_option',
        'La misión y al menos una opción son obligatorias.',
      );
    }
    return _trainingStore.checkAndRecord(
      userId: user.id,
      missionId: missionId,
      optionIds: selected.toList(growable: false),
      hintUsed: hintUsed,
    );
  }

  void _requireStudent(UserModel user) {
    if (user.role != UserRole.student) {
      throw const CatalogException(
        'forbidden',
        'El entrenamiento requiere una cuenta estudiantil.',
      );
    }
  }
}
