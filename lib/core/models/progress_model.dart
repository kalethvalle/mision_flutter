import 'mission_model.dart';

class MissionProgressState {
  const MissionProgressState({
    required this.missionId,
    required this.worldId,
    required this.isCompleted,
    required this.isUnlocked,
  });

  final String missionId;
  final String worldId;
  final bool isCompleted;
  final bool isUnlocked;

  factory MissionProgressState.fromJson(Map<String, Object?> json) {
    return MissionProgressState(
      missionId: json.string('missionId'),
      worldId: json.string('worldId'),
      isCompleted: _boolean(json, 'isCompleted'),
      isUnlocked: _boolean(json, 'isUnlocked'),
    );
  }

  Map<String, Object?> toJson() => {
    'missionId': missionId,
    'worldId': worldId,
    'isCompleted': isCompleted,
    'isUnlocked': isUnlocked,
  };
}

class WorldProgressState {
  const WorldProgressState({
    required this.worldId,
    required this.completedMissions,
    required this.totalMissions,
    required this.isUnlocked,
    this.lockReason,
  });

  final String worldId;
  final int completedMissions;
  final int totalMissions;
  final bool isUnlocked;
  final String? lockReason;

  factory WorldProgressState.fromJson(Map<String, Object?> json) {
    return WorldProgressState(
      worldId: json.string('worldId'),
      completedMissions: _integer(json, 'completedMissions'),
      totalMissions: _integer(json, 'totalMissions'),
      isUnlocked: _boolean(json, 'isUnlocked'),
      lockReason: json['lockReason'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'worldId': worldId,
    'completedMissions': completedMissions,
    'totalMissions': totalMissions,
    'isUnlocked': isUnlocked,
    'lockReason': lockReason,
  };
}

class StudentProgress {
  const StudentProgress({required this.worlds, required this.missions});

  const StudentProgress.empty() : worlds = const [], missions = const [];

  final List<WorldProgressState> worlds;
  final List<MissionProgressState> missions;

  factory StudentProgress.fromJson(Map<String, Object?> json) {
    return StudentProgress(
      worlds: json
          .objectList('worlds')
          .map(WorldProgressState.fromJson)
          .toList(),
      missions: json
          .objectList('missions')
          .map(MissionProgressState.fromJson)
          .toList(),
    );
  }

  WorldProgressState? world(String worldId) {
    return worlds.where((item) => item.worldId == worldId).firstOrNull;
  }

  MissionProgressState? mission(String missionId) {
    return missions.where((item) => item.missionId == missionId).firstOrNull;
  }

  Map<String, Object?> toJson() => {
    'worlds': worlds.map((world) => world.toJson()).toList(),
    'missions': missions.map((mission) => mission.toJson()).toList(),
  };
}

bool _boolean(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('El campo "$key" debe ser booleano.');
  }
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('El campo "$key" debe ser entero.');
  }
  return value;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
