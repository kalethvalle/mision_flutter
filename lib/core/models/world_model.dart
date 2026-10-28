import 'mission_model.dart';

class TopicModel {
  const TopicModel({
    required this.id,
    required this.worldId,
    required this.title,
    required this.description,
  });

  final String id;
  final String worldId;
  final String title;
  final String description;

  factory TopicModel.fromJson(Map<String, Object?> json) => TopicModel(
    id: json.string('id'),
    worldId: json.string('worldId'),
    title: json.string('title'),
    description: json.string('description'),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'worldId': worldId,
    'title': title,
    'description': description,
  };
}

class WorldModel {
  const WorldModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.colorHex,
    required this.topics,
    this.isUnlocked = false,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final String colorHex;
  final List<TopicModel> topics;
  final bool isUnlocked;

  factory WorldModel.fromJson(Map<String, Object?> json) => WorldModel(
    id: json.string('id'),
    title: json.string('title'),
    description: json.string('description'),
    iconKey: json.string('iconKey'),
    colorHex: json.string('colorHex'),
    topics: json.objectList('topics').map(TopicModel.fromJson).toList(),
  );

  WorldModel copyWith({bool? isUnlocked}) => WorldModel(
    id: id,
    title: title,
    description: description,
    iconKey: iconKey,
    colorHex: colorHex,
    topics: topics,
    isUnlocked: isUnlocked ?? this.isUnlocked,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'iconKey': iconKey,
    'colorHex': colorHex,
    'topics': topics.map((topic) => topic.toJson()).toList(),
  };
}
