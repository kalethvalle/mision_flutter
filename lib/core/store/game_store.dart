import 'package:flutter/foundation.dart';

import '../models/mission_model.dart';
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
  bool _isWorld1Completed = false;
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

  List<WorldModel> get worlds {
    return _catalogWorlds
        .asMap()
        .entries
        .map((entry) {
          final unlocked =
              entry.key == 0 ||
              entry.value.id == 'world_1' ||
              (entry.value.id == 'world_2' && _isWorld1Completed);
          return entry.value.copyWith(isUnlocked: unlocked);
        })
        .toList(growable: false);
  }

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
  bool get hasNextMission =>
      _currentMissionIndex < currentWorldMissions.length - 1;
  bool get hasPrevMission => _currentMissionIndex > 0;

  Future<void> initialize() async {
    if (_worldsState == LoadState.loading) return;
    _worldsState = LoadState.loading;
    _worldsError = null;
    notifyListeners();
    try {
      _catalogWorlds = await _catalogRepository.listWorlds();
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
      );
      if (generation != _answerGeneration ||
          currentMissionOrNull?.id != mission.id ||
          _selectedOptionId != optionId) {
        return;
      }
      _isSuccess = result.isCorrect;
      _showError = !result.isCorrect;
      if (result.isCorrect &&
          _selectedWorldId == 'world_1' &&
          !hasNextMission) {
        _isWorld1Completed = true;
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
    _missionsError = null;
    if (notify) notifyListeners();
  }

  String _messageFor(Object error) {
    if (error is CatalogException) return error.message;
    return 'No fue posible conectar con el catálogo local.';
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
