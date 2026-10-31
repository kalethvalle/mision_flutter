enum MissionCategory {
  dartBasics('dart_basics'),
  layout('layout'),
  interactivity('interactivity');

  const MissionCategory(this.wireName);

  final String wireName;

  static MissionCategory fromWireName(String value) {
    return values.firstWhere(
      (category) => category.wireName == value,
      orElse: () =>
          throw FormatException('Categoría de misión no compatible: $value'),
    );
  }
}

class MissionOption {
  const MissionOption({
    required this.id,
    required this.label,
    required this.codeSnippet,
  });

  final String id;
  final String label;
  final String codeSnippet;

  factory MissionOption.fromJson(Map<String, Object?> json) {
    return MissionOption(
      id: json.string('id'),
      label: json.string('label'),
      codeSnippet: json.string('codeSnippet'),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'codeSnippet': codeSnippet,
  };
}

class MissionModel {
  const MissionModel({
    required this.id,
    required this.worldId,
    required this.worldTitle,
    required this.topicId,
    required this.missionTitle,
    required this.description,
    required this.learningContextParagraphs,
    required this.instructions,
    required this.hint,
    required this.category,
    required this.codeTemplate,
    required this.targetPlaceholder,
    required this.options,
    required this.previewType,
  });

  final String id;
  final String worldId;
  final String worldTitle;
  final String topicId;
  final String missionTitle;
  final String description;
  final List<String> learningContextParagraphs;
  final List<String> instructions;
  final String hint;
  final MissionCategory category;
  final List<String> codeTemplate;
  final String targetPlaceholder;
  final List<MissionOption> options;
  final String previewType;

  factory MissionModel.fromJson(Map<String, Object?> json) {
    return MissionModel(
      id: json.string('id'),
      worldId: json.string('worldId'),
      worldTitle: json.string('worldTitle'),
      topicId: json.string('topicId'),
      missionTitle: json.string('missionTitle'),
      description: json.string('description'),
      learningContextParagraphs: json.stringList('learningContextParagraphs'),
      instructions: json.stringList('instructions'),
      hint: json.string('hint'),
      category: MissionCategory.fromWireName(json.string('category')),
      codeTemplate: json.stringList('codeTemplate'),
      targetPlaceholder: json.string('targetPlaceholder'),
      options: json.objectList('options').map(MissionOption.fromJson).toList(),
      previewType: json.string('previewType'),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'worldId': worldId,
    'worldTitle': worldTitle,
    'topicId': topicId,
    'missionTitle': missionTitle,
    'description': description,
    'learningContextParagraphs': learningContextParagraphs,
    'instructions': instructions,
    'hint': hint,
    'category': category.wireName,
    'codeTemplate': codeTemplate,
    'targetPlaceholder': targetPlaceholder,
    'options': options.map((option) => option.toJson()).toList(),
    'previewType': previewType,
  };
}

extension JsonObjectReader on Map<String, Object?> {
  String string(String key) {
    final value = this[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('El campo "$key" debe ser texto no vacío.');
    }
    return value;
  }

  List<String> stringList(String key) {
    final value = this[key];
    if (value is! List<Object?> || value.any((item) => item is! String)) {
      throw FormatException('El campo "$key" debe ser una lista de textos.');
    }
    return value.cast<String>();
  }

  List<Map<String, Object?>> objectList(String key) {
    final value = this[key];
    if (value is! List<Object?>) {
      throw FormatException('El campo "$key" debe ser una lista.');
    }
    return value.map((item) {
      if (item is! Map<String, Object?>) {
        throw FormatException('Los elementos de "$key" deben ser objetos.');
      }
      return item;
    }).toList();
  }
}
