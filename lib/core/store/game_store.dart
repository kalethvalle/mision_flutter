import 'package:flutter/foundation.dart';

import '../models/mission_model.dart';
import '../models/progress_model.dart';
import '../models/world_model.dart';
import '../repositories/catalog_repository.dart';

enum ActiveScreen { worldMap, mission }

enum LoadState { initial, loading, ready, empty, failure }

class GameStore extends ChangeNotifier {
  GameStore(this._catalogRepository);

  final FlutterQuestRepository _catalogRepository;

  ActiveScreen _activeScreen = ActiveScreen.worldMap;
  LoadState _worldsState = LoadState.initial;
  LoadState _missionsState = LoadState.initial;
  List<WorldModel> _catalogWorlds = const [];
  final Map<String, List<MissionModel>> _missionsByWorld = {};
  String? _selectedWorldId;
  int _currentMissionIndex = 0;
  String _selectedOptionId = '';
  bool _isSuccess = false;
  bool _showError = false;
  bool _isCheckingAnswer = false;
  bool _hintUsed = false;
  StudentProgress _progress = const StudentProgress.empty();
  String? _worldsError;
  String? _missionsError;
  int _loadGeneration = 0;
  int _answerGeneration = 0;

  ActiveScreen get activeScreen => _activeScreen;
  LoadState get worldsState => _worldsState;
  LoadState get missionsState => _missionsState;
  String? get worldsError => _worldsError;
  String? get missionsError => _missionsError;
  String? get selectedWorldId => _selectedWorldId;
  String get selectedOptionId => _selectedOptionId;
  bool get isSuccess => _isSuccess;
  bool get showError => _showError;
  bool get isCheckingAnswer => _isCheckingAnswer;
  bool get hintUsed => _hintUsed;
  StudentProgress get progress => _progress;
  bool get isCurrentMissionCompleted {
    final mission = currentMissionOrNull;
    return mission != null &&
        (_progress.mission(mission.id)?.isCompleted ?? false);
  }

  List<WorldModel> get worlds {
    return _catalogWorlds
        .map((world) {
          final unlocked = _progress.world(world.id)?.isUnlocked ?? false;
          return world.copyWith(isUnlocked: unlocked);
        })
        .toList(growable: false);
  }

  WorldProgressState? worldProgress(String worldId) => _progress.world(worldId);

  List<MissionModel> get currentWorldMissions {
    final worldId = _selectedWorldId;
    if (worldId == null) return const [];
    return _missionsByWorld[worldId] ?? const [];
  }

  MissionModel? get currentMissionOrNull {
    final missions = currentWorldMissions;
    if (_currentMissionIndex < 0 || _currentMissionIndex >= missions.length) {
      return null;
    }
    return missions[_currentMissionIndex];
  }

  MissionModel get currentMission {
    final mission = currentMissionOrNull;
    if (mission == null) {
      throw StateError('No hay una misión cargada.');
    }
    return mission;
  }

  int get currentMissionNumber => _currentMissionIndex + 1;
  int get totalMissions => currentWorldMissions.length;
  bool get hasNextMission {
    final nextIndex = _currentMissionIndex + 1;
    if (nextIndex >= currentWorldMissions.length) return false;
    final nextMission = currentWorldMissions[nextIndex];
    return _progress.mission(nextMission.id)?.isUnlocked ?? false;
  }

  bool get hasPrevMission => _currentMissionIndex > 0;

  Future<void> initialize() async {
    if (_worldsState == LoadState.loading) return;
    _worldsState = LoadState.loading;
    _worldsError = null;
    notifyListeners();
    try {
      final results = await Future.wait<Object>([
        _catalogRepository.listWorlds(),
        _catalogRepository.getProgress(),
      ]);
      _catalogWorlds = results[0] as List<WorldModel>;
      _progress = results[1] as StudentProgress;
      _worldsState = _catalogWorlds.isEmpty ? LoadState.empty : LoadState.ready;
    } on Object catch (error) {
      _worldsState = LoadState.failure;
      _worldsError = _messageFor(error);
    }
    notifyListeners();
  }

  Future<void> retryWorlds() => initialize();

  Future<void> selectWorld(String worldId) async {
    final world = worlds.where((item) => item.id == worldId).firstOrNull;
    if (world == null || !world.isUnlocked) return;

    _selectedWorldId = worldId;
    _currentMissionIndex = 0;
    _activeScreen = ActiveScreen.mission;
    _resetMissionState(notify: false);

    final cached = _missionsByWorld[worldId];
    if (cached != null) {
      _currentMissionIndex = _initialMissionIndex(cached);
      _missionsState = cached.isEmpty ? LoadState.empty : LoadState.ready;
      notifyListeners();
      return;
    }
    await _loadMissions(worldId);
  }

  Future<void> retryCurrentWorld() async {
    final worldId = _selectedWorldId;
    if (worldId == null) return;
    await _loadMissions(worldId);
  }

  Future<void> _loadMissions(String worldId) async {
    final generation = ++_loadGeneration;
    _missionsState = LoadState.loading;
    _missionsError = null;
    notifyListeners();
    try {
      final missions = await _catalogRepository.listWorldMissions(worldId);
      if (generation != _loadGeneration || worldId != _selectedWorldId) return;
      _missionsByWorld[worldId] = missions;
      _currentMissionIndex = _initialMissionIndex(missions);
      _missionsState = missions.isEmpty ? LoadState.empty : LoadState.ready;
    } on Object catch (error) {
      if (generation != _loadGeneration || worldId != _selectedWorldId) return;
      _missionsState = LoadState.failure;
      _missionsError = _messageFor(error);
    }
    notifyListeners();
  }

  void goToWorldMap() {
    _loadGeneration++;
    _answerGeneration++;
    _activeScreen = ActiveScreen.worldMap;
    notifyListeners();
  }

  void selectOption(String optionId) {
    _answerGeneration++;
    _selectedOptionId = optionId;
    _isSuccess = false;
    _showError = false;
    _isCheckingAnswer = false;
    _missionsError = null;
    notifyListeners();
  }

  void markHintUsed() {
    if (_hintUsed) return;
    _hintUsed = true;
    notifyListeners();
  }

  Future<void> checkAnswer() async {
    final mission = currentMissionOrNull;
    final optionId = _selectedOptionId;
    if (mission == null || optionId.isEmpty || _isCheckingAnswer) return;

    final generation = ++_answerGeneration;
    _isCheckingAnswer = true;
    _isSuccess = false;
    _showError = false;
    _missionsError = null;
    notifyListeners();
    try {
      final result = await _catalogRepository.checkMissionAnswer(
        mission.id,
        optionId,
        hintUsed: _hintUsed,
      );
      if (generation != _answerGeneration ||
          currentMissionOrNull?.id != mission.id ||
          _selectedOptionId != optionId) {
        return;
      }
      _isSuccess = result.isCorrect;
      _showError = !result.isCorrect;
      if (result.progress != null) {
        _progress = result.progress!;
      } else if (result.isCorrect) {
        _progress = await _catalogRepository.getProgress();
      }
    } on Object catch (error) {
      if (generation != _answerGeneration) return;
      _showError = true;
      _missionsError = _messageFor(error);
    } finally {
      if (generation == _answerGeneration) {
        _isCheckingAnswer = false;
        notifyListeners();
      }
    }
  }

  void nextMission() {
    if (!hasNextMission) return;
    _currentMissionIndex++;
    _resetMissionState();
  }

  void previousMission() {
    if (!hasPrevMission) return;
    _currentMissionIndex--;
    _resetMissionState();
  }

  void _resetMissionState({bool notify = true}) {
    _answerGeneration++;
    _selectedOptionId = '';
    _isSuccess = false;
    _showError = false;
    _isCheckingAnswer = false;
    _hintUsed = false;
    _missionsError = null;
    if (notify) notifyListeners();
  }

  int _initialMissionIndex(List<MissionModel> missions) {
    if (missions.isEmpty) return 0;
    final firstIncomplete = missions.indexWhere((mission) {
      final state = _progress.mission(mission.id);
      return state != null && state.isUnlocked && !state.isCompleted;
    });
    if (firstIncomplete >= 0) return firstIncomplete;
    final lastUnlocked = missions.lastIndexWhere(
      (mission) => _progress.mission(mission.id)?.isUnlocked ?? false,
    );
    return lastUnlocked < 0 ? 0 : lastUnlocked;
  }

  String _messageFor(Object error) {
    if (error is CatalogException) return error.message;
    return 'No fue posible conectar con el catálogo local.';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
