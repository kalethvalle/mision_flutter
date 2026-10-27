import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../models/world_model.dart';
import 'world/syntax_dart/syntax_dart_world.dart';
import 'world/layout/layout_world.dart';

enum ActiveScreen { worldMap, mission }

class GameStore extends ChangeNotifier {
  ActiveScreen _activeScreen = ActiveScreen.worldMap;
  String? _selectedWorldId;
  int _currentMissionIndex = 0;
  String _selectedOptionId = '';
  bool _isSuccess = false;
  bool _showError = false;
  bool _isWorld1Completed = false;

  // Unificación de todas las misiones importadas por módulo
  List<MissionModel> get _allMissions => [
        ...syntaxDartMissions,
        ...layoutMissions,
      ];

  List<WorldModel> get worlds => [
        WorldModel(
          id: 'world_1',
          title: 'Mundo 1: Fundamentos de Dart',
          description: 'Aprende variables, funciones, listas y null safety.',
          icon: Icons.code_rounded,
          color: const Color(0xFF38BDF8),
          isUnlocked: true,
        ),
        WorldModel(
          id: 'world_2',
          title: 'Mundo 2: Layouts & Flexbox',
          description: 'Alinea y distribuye widgets con Row, Column y Stack.',
          icon: Icons.widgets_rounded,
          color: const Color(0xFFA855F7),
          isUnlocked: _isWorld1Completed,
        ),
      ];

  // Getters & Métodos de estado
  ActiveScreen get activeScreen => _activeScreen;
  String? get selectedWorldId => _selectedWorldId;

  List<MissionModel> get currentWorldMissions =>
      _allMissions.where((m) => m.worldId == _selectedWorldId).toList();

  MissionModel get currentMission => currentWorldMissions[_currentMissionIndex];
  int get currentMissionNumber => _currentMissionIndex + 1;
  int get totalMissions => currentWorldMissions.length;
  String get selectedOptionId => _selectedOptionId;
  bool get isSuccess => _isSuccess;
  bool get showError => _showError;
  bool get hasNextMission => _currentMissionIndex < currentWorldMissions.length - 1;
  bool get hasPrevMission => _currentMissionIndex > 0;

  void selectWorld(String worldId) {
    _selectedWorldId = worldId;
    _currentMissionIndex = 0;
    _activeScreen = ActiveScreen.mission;
    _resetMissionState();
  }

  void goToWorldMap() {
    _activeScreen = ActiveScreen.worldMap;
    notifyListeners();
  }

  void selectOption(String optionId) {
    _selectedOptionId = optionId;
    _isSuccess = false;
    _showError = false;
    notifyListeners();
  }

  void checkAnswer() {
    if (_selectedOptionId == currentMission.correctOptionId) {
      _isSuccess = true;
      _showError = false;

      if (_selectedWorldId == 'world_1' && !hasNextMission) {
        _isWorld1Completed = true;
      }
    } else {
      _isSuccess = false;
      _showError = true;
    }
    notifyListeners();
  }

  void nextMission() {
    if (hasNextMission) {
      _currentMissionIndex++;
      _resetMissionState();
    }
  }

  void previousMission() {
    if (hasPrevMission) {
      _currentMissionIndex--;
      _resetMissionState();
    }
  }

  void _resetMissionState() {
    _selectedOptionId = '';
    _isSuccess = false;
    _showError = false;
    notifyListeners();
  }
}