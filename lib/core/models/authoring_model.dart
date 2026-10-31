import 'mission_model.dart';

enum ContentStatus {
  draft('draft'),
  published('published');

  const ContentStatus(this.wireName);

  final String wireName;

  static ContentStatus fromWireName(String value) => values.firstWhere(
    (status) => status.wireName == value,
    orElse: () => throw FormatException('Estado no compatible: $value'),
  );
}

enum QuestionType {
  single('single'),
  multiple('multiple');

  const QuestionType(this.wireName);

  final String wireName;

  static QuestionType fromWireName(String value) => values.firstWhere(
    (type) => type.wireName == value,
    orElse: () => throw FormatException('Tipo no compatible: $value'),
  );
}

class AuthoringWorld {
  const AuthoringWorld({
    this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.colorHex,
    required this.sortOrder,
    required this.status,
  });

  final String? id;
  final String title;
  final String description;
  final String iconKey;
  final String colorHex;
  final int sortOrder;
  final ContentStatus status;

  factory AuthoringWorld.fromJson(Map<String, Object?> json) => AuthoringWorld(
    id: json.optionalString('id'),
    title: json.text('title'),
    description: json.text('description'),
    iconKey: json.text('iconKey'),
    colorHex: json.text('colorHex'),
    sortOrder: json.integer('sortOrder'),
    status: ContentStatus.fromWireName(json.text('status')),
  );

  Map<String, Object?> toJson() => {
    if (id != null) 'id': id,
    'title': title,
    'description': description,
    'iconKey': iconKey,
    'colorHex': colorHex,
    'sortOrder': sortOrder,
    'status': status.wireName,
  };
}

class AuthoringTopic {
  const AuthoringTopic({
    this.id,
    required this.worldId,
    required this.title,
    required this.description,
    required this.sortOrder,
    required this.status,
  });

  final String? id;
  final String worldId;
  final String title;
  final String description;
  final int sortOrder;
  final ContentStatus status;

  factory AuthoringTopic.fromJson(Map<String, Object?> json) => AuthoringTopic(
    id: json.optionalString('id'),
    worldId: json.text('worldId'),
    title: json.text('title'),
    description: json.text('description'),
    sortOrder: json.integer('sortOrder'),
    status: ContentStatus.fromWireName(json.text('status')),
  );

  Map<String, Object?> toJson() => {
    if (id != null) 'id': id,
    'worldId': worldId,
    'title': title,
    'description': description,
    'sortOrder': sortOrder,
    'status': status.wireName,
  };
}

class AuthoringMissionOption {
  const AuthoringMissionOption({
    required this.id,
    required this.label,
    required this.codeSnippet,
    required this.isCorrect,
  });

  final String id;
  final String label;
  final String codeSnippet;
  final bool isCorrect;

  factory AuthoringMissionOption.fromJson(Map<String, Object?> json) =>
      AuthoringMissionOption(
        id: json.text('id'),
        label: json.text('label'),
        codeSnippet: json.text('codeSnippet'),
        isCorrect: json.boolean('isCorrect'),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'codeSnippet': codeSnippet,
    'isCorrect': isCorrect,
  };
}

class AuthoringMission {
  const AuthoringMission({
    this.id,
    required this.worldId,
    required this.topicId,
    required this.title,
    required this.description,
    required this.paragraphs,
    required this.instructions,
    required this.hint,
    required this.category,
    required this.codeTemplate,
    required this.targetPlaceholder,
    required this.previewType,
    required this.sortOrder,
    required this.status,
    required this.contentVersion,
    required this.options,
  });

  final String? id;
  final String worldId;
  final String topicId;
  final String title;
  final String description;
  final List<String> paragraphs;
  final List<String> instructions;
  final String hint;
  final MissionCategory category;
  final List<String> codeTemplate;
  final String targetPlaceholder;
  final String previewType;
  final int sortOrder;
  final ContentStatus status;
  final int contentVersion;
  final List<AuthoringMissionOption> options;

  factory AuthoringMission.fromJson(Map<String, Object?> json) =>
      AuthoringMission(
        id: json.optionalString('id'),
        worldId: json.text('worldId'),
        topicId: json.text('topicId'),
        title: json.text('title'),
        description: json.text('description'),
        paragraphs: json.textList('paragraphs'),
        instructions: json.textList('instructions'),
        hint: json.text('hint'),
        category: MissionCategory.fromWireName(json.text('category')),
        codeTemplate: json.textList('codeTemplate'),
        targetPlaceholder: json.text('targetPlaceholder'),
        previewType: json.text('previewType'),
        sortOrder: json.integer('sortOrder'),
        status: ContentStatus.fromWireName(json.text('status')),
        contentVersion: json.integer('contentVersion'),
        options: json
            .objects('options')
            .map(AuthoringMissionOption.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    if (id != null) 'id': id,
    'worldId': worldId,
    'topicId': topicId,
    'title': title,
    'description': description,
    'paragraphs': paragraphs,
    'instructions': instructions,
    'hint': hint,
    'category': category.wireName,
    'codeTemplate': codeTemplate,
    'targetPlaceholder': targetPlaceholder,
    'previewType': previewType,
    'sortOrder': sortOrder,
    'status': status.wireName,
    'contentVersion': contentVersion,
    'options': options.map((option) => option.toJson()).toList(),
  };
}

class AuthoringQuestionOption {
  const AuthoringQuestionOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  final String id;
  final String text;
  final bool isCorrect;

  factory AuthoringQuestionOption.fromJson(Map<String, Object?> json) =>
      AuthoringQuestionOption(
        id: json.text('id'),
        text: json.text('text'),
        isCorrect: json.boolean('isCorrect'),
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'isCorrect': isCorrect,
  };
}

class AuthoringQuestion {
  const AuthoringQuestion({
    this.id,
    required this.worldId,
    required this.topicId,
    required this.prompt,
    required this.type,
    required this.explanation,
    required this.status,
    required this.contentVersion,
    required this.options,
  });

  final String? id;
  final String worldId;
  final String topicId;
  final String prompt;
  final QuestionType type;
  final String explanation;
  final ContentStatus status;
  final int contentVersion;
  final List<AuthoringQuestionOption> options;

  factory AuthoringQuestion.fromJson(Map<String, Object?> json) =>
      AuthoringQuestion(
        id: json.optionalString('id'),
        worldId: json.text('worldId'),
        topicId: json.text('topicId'),
        prompt: json.text('prompt'),
        type: QuestionType.fromWireName(json.text('type')),
        explanation: json.text('explanation'),
        status: ContentStatus.fromWireName(json.text('status')),
        contentVersion: json.integer('contentVersion'),
        options: json
            .objects('options')
            .map(AuthoringQuestionOption.fromJson)
            .toList(),
      );

  Map<String, Object?> toJson() => {
    if (id != null) 'id': id,
    'worldId': worldId,
    'topicId': topicId,
    'prompt': prompt,
    'type': type.wireName,
    'explanation': explanation,
    'status': status.wireName,
    'contentVersion': contentVersion,
    'options': options.map((option) => option.toJson()).toList(),
  };
}

class AuthoringCatalog {
  const AuthoringCatalog({
    required this.worlds,
    required this.topics,
    required this.missions,
    required this.questions,
    required this.previewTypes,
  });

  final List<AuthoringWorld> worlds;
  final List<AuthoringTopic> topics;
  final List<AuthoringMission> missions;
  final List<AuthoringQuestion> questions;
  final List<String> previewTypes;

  factory AuthoringCatalog.fromJson(Map<String, Object?> json) =>
      AuthoringCatalog(
        worlds: json.objects('worlds').map(AuthoringWorld.fromJson).toList(),
        topics: json.objects('topics').map(AuthoringTopic.fromJson).toList(),
        missions: json
            .objects('missions')
            .map(AuthoringMission.fromJson)
            .toList(),
        questions: json
            .objects('questions')
            .map(AuthoringQuestion.fromJson)
            .toList(),
        previewTypes: json.textList('previewTypes'),
      );

  Map<String, Object?> toJson() => {
    'worlds': worlds.map((item) => item.toJson()).toList(),
    'topics': topics.map((item) => item.toJson()).toList(),
    'missions': missions.map((item) => item.toJson()).toList(),
    'questions': questions.map((item) => item.toJson()).toList(),
    'previewTypes': previewTypes,
  };
}

extension AuthoringJsonReader on Map<String, Object?> {
  String text(String key) {
    final value = this[key];
    if (value is! String) throw FormatException('"$key" debe ser texto.');
    return value;
  }

  String? optionalString(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('"$key" debe ser texto.');
    return value;
  }

  int integer(String key) {
    final value = this[key];
    if (value is! int) throw FormatException('"$key" debe ser entero.');
    return value;
  }

  bool boolean(String key) {
    final value = this[key];
    if (value is! bool) throw FormatException('"$key" debe ser booleano.');
    return value;
  }

  List<String> textList(String key) {
    final value = this[key];
    if (value is! List<Object?> || value.any((item) => item is! String)) {
      throw FormatException('"$key" debe ser una lista de textos.');
    }
    return value.cast<String>();
  }

  List<Map<String, Object?>> objects(String key) {
    final value = this[key];
    if (value is! List<Object?> ||
        value.any((item) => item is! Map<String, Object?>)) {
      throw FormatException('"$key" debe ser una lista de objetos.');
    }
    return value.cast<Map<String, Object?>>();
  }
}
