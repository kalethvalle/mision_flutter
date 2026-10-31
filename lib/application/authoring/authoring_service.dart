import '../../core/models/authoring_model.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/catalog_repository.dart';

abstract interface class ContentAuthoringStore {
  Future<AuthoringCatalog> loadCatalog(List<String> previewTypes);

  Future<AuthoringWorld> saveWorld(AuthoringWorld world);

  Future<AuthoringTopic> saveTopic(AuthoringTopic topic);

  Future<AuthoringMission> saveMission(AuthoringMission mission);

  Future<AuthoringQuestion> saveQuestion(AuthoringQuestion question);
}

class AuthoringService {
  const AuthoringService(this._store);

  static const previewTypes = [
    'dart.variables',
    'dart.final',
    'dart.arrow',
    'dart.lists',
    'dart.null_safety',
    'flutter.row',
    'flutter.column',
    'flutter.padding',
    'flutter.stack',
  ];

  static const worldIconKeys = ['code', 'widgets', 'public'];

  final ContentAuthoringStore _store;

  Future<AuthoringCatalog> load(UserModel actor) {
    _requireTeacher(actor);
    return _store.loadCatalog(previewTypes);
  }

  Future<AuthoringWorld> saveWorld(UserModel actor, AuthoringWorld world) {
    _requireTeacher(actor);
    final errors = <String>[];
    _positiveOrder(world.sortOrder, errors);
    if (world.status == ContentStatus.published) {
      _required(world.title, 'título', errors);
      _required(world.description, 'descripción', errors);
      if (!worldIconKeys.contains(world.iconKey)) {
        errors.add('selecciona un icono permitido');
      }
      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(world.colorHex)) {
        errors.add('usa un color hexadecimal #RRGGBB');
      }
    }
    _throwValidation(errors);
    return _store.saveWorld(world);
  }

  Future<AuthoringTopic> saveTopic(UserModel actor, AuthoringTopic topic) {
    _requireTeacher(actor);
    final errors = <String>[];
    _required(topic.worldId, 'mundo', errors);
    _positiveOrder(topic.sortOrder, errors);
    if (topic.status == ContentStatus.published) {
      _required(topic.title, 'título', errors);
      _required(topic.description, 'descripción', errors);
    }
    _throwValidation(errors);
    return _store.saveTopic(topic);
  }

  Future<AuthoringMission> saveMission(
    UserModel actor,
    AuthoringMission mission,
  ) {
    _requireTeacher(actor);
    final errors = <String>[];
    _required(mission.worldId, 'mundo', errors);
    _required(mission.topicId, 'tema', errors);
    _positiveOrder(mission.sortOrder, errors);
    _validateOptionIds(mission.options.map((option) => option.id), errors);
    if (mission.status == ContentStatus.published) {
      _required(mission.title, 'título', errors);
      _required(mission.description, 'objetivo', errors);
      _required(mission.hint, 'pista', errors);
      if (mission.paragraphs.length != 2 ||
          mission.paragraphs.any((text) => text.trim().isEmpty)) {
        errors.add('incluye exactamente dos párrafos');
      }
      if (mission.instructions.length != 3 ||
          mission.instructions.any((text) => text.trim().isEmpty)) {
        errors.add('incluye exactamente tres pasos');
      }
      if (mission.codeTemplate.isEmpty ||
          mission.codeTemplate.every((line) => line.trim().isEmpty)) {
        errors.add('incluye una plantilla de código');
      }
      _required(mission.targetPlaceholder, 'marcador', errors);
      if (mission.targetPlaceholder.trim().isNotEmpty &&
          !mission.codeTemplate.any(
            (line) => line.contains(mission.targetPlaceholder),
          )) {
        errors.add('incluye el marcador dentro de la plantilla');
      }
      if (!previewTypes.contains(mission.previewType)) {
        errors.add('selecciona una vista previa implementada');
      }
      if (mission.options.length < 2) {
        errors.add('incluye al menos dos opciones');
      }
      if (mission.options.any(
        (option) =>
            option.label.trim().isEmpty || option.codeSnippet.trim().isEmpty,
      )) {
        errors.add('completa el texto y código de cada opción');
      }
      if (mission.options.where((option) => option.isCorrect).length != 1) {
        errors.add('marca exactamente una opción correcta');
      }
    }
    _throwValidation(errors);
    return _store.saveMission(mission);
  }

  Future<AuthoringQuestion> saveQuestion(
    UserModel actor,
    AuthoringQuestion question,
  ) {
    _requireTeacher(actor);
    final errors = <String>[];
    _required(question.worldId, 'mundo', errors);
    _required(question.topicId, 'tema', errors);
    _validateOptionIds(question.options.map((option) => option.id), errors);
    if (question.status == ContentStatus.published) {
      _required(question.prompt, 'enunciado', errors);
      _required(question.explanation, 'explicación', errors);
      if (question.options.length < 2) {
        errors.add('incluye al menos dos opciones');
      }
      if (question.options.any((option) => option.text.trim().isEmpty)) {
        errors.add('completa el texto de cada opción');
      }
      final correct = question.options
          .where((option) => option.isCorrect)
          .length;
      if (question.type == QuestionType.single && correct != 1) {
        errors.add('selección única requiere exactamente una correcta');
      }
      if (question.type == QuestionType.multiple && correct < 1) {
        errors.add('selección múltiple requiere al menos una correcta');
      }
    }
    _throwValidation(errors);
    return _store.saveQuestion(question);
  }

  void _requireTeacher(UserModel actor) {
    if (actor.role != UserRole.teacher) {
      throw const CatalogException(
        'forbidden',
        'Esta operación requiere el rol docente.',
      );
    }
  }

  void _positiveOrder(int order, List<String> errors) {
    if (order < 1) errors.add('el orden debe ser mayor que cero');
  }

  void _required(String value, String field, List<String> errors) {
    if (value.trim().isEmpty) errors.add('completa $field');
  }

  void _validateOptionIds(Iterable<String> ids, List<String> errors) {
    final values = ids.toList();
    if (values.toSet().length != values.length ||
        values.any((id) => !RegExp(r'^[A-Za-z0-9._-]{1,64}$').hasMatch(id))) {
      errors.add('usa identificadores de opción únicos y válidos');
    }
  }

  void _throwValidation(List<String> errors) {
    if (errors.isNotEmpty) {
      throw CatalogException('validation_failed', errors.join('; '));
    }
  }
}
