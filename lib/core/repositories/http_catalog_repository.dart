import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/answer_check_result.dart';
import '../models/authoring_model.dart';
import '../models/mission_model.dart';
import '../models/progress_model.dart';
import '../models/user_model.dart';
import '../models/world_model.dart';
import 'catalog_repository.dart';

class HttpCatalogRepository implements FlutterQuestRepository {
  factory HttpCatalogRepository({
    required http.Client client,
    required Uri baseUri,
  }) => HttpCatalogRepository._(client, baseUri);

  HttpCatalogRepository._(this._client, Uri baseUri)
    : _baseUri = baseUri.path.endsWith('/')
          ? baseUri
          : baseUri.replace(path: '${baseUri.path}/');

  final http.Client _client;
  final Uri _baseUri;

  @override
  Future<List<WorldModel>> listWorlds() async {
    final json = await _get('worlds');
    return json.objectList('worlds').map(WorldModel.fromJson).toList();
  }

  @override
  Future<List<MissionModel>> listWorldMissions(String worldId) async {
    final json = await _get('worlds/${Uri.encodeComponent(worldId)}/missions');
    return json.objectList('missions').map(MissionModel.fromJson).toList();
  }

  @override
  Future<MissionModel?> getMission(String missionId) async {
    try {
      final json = await _get('missions/${Uri.encodeComponent(missionId)}');
      return MissionModel.fromJson(_object(json, 'mission'));
    } on CatalogException catch (error) {
      if (error.code == 'mission_not_found') return null;
      rethrow;
    }
  }

  @override
  Future<AnswerCheckResult> checkMissionAnswer(
    String missionId,
    String optionId, {
    required bool hintUsed,
  }) async {
    final json = await _post(
      'missions/${Uri.encodeComponent(missionId)}/check',
      {'optionId': optionId, 'hintUsed': hintUsed},
    );
    return AnswerCheckResult.fromJson(_object(json, 'result'));
  }

  @override
  Future<AuthSnapshot> getAuthStatus() async {
    return AuthSnapshot.fromJson(await _get('auth/status'));
  }

  @override
  Future<UserModel> bootstrapTeacher({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final json = await _post('auth/bootstrap', {
      'username': username,
      'displayName': displayName,
      'password': password,
    });
    return UserModel.fromJson(_object(json, 'user'));
  }

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final json = await _post('auth/login', {
      'username': username,
      'password': password,
    });
    return UserModel.fromJson(_object(json, 'user'));
  }

  @override
  Future<void> logout() async {
    await _post('auth/logout', const {});
  }

  @override
  Future<List<UserModel>> listUsers() async {
    final json = await _get('users');
    return json.objectList('users').map(UserModel.fromJson).toList();
  }

  @override
  Future<UserModel> createStudent({
    required String username,
    required String displayName,
    required String password,
  }) async {
    final json = await _post('users', {
      'username': username,
      'displayName': displayName,
      'password': password,
    });
    return UserModel.fromJson(_object(json, 'user'));
  }

  @override
  Future<StudentProgress> getProgress() async {
    final json = await _get('progress');
    return StudentProgress.fromJson(_object(json, 'progress'));
  }

  @override
  Future<AuthoringCatalog> getAuthoringCatalog() async {
    final json = await _get('authoring');
    return AuthoringCatalog.fromJson(_object(json, 'catalog'));
  }

  @override
  Future<AuthoringWorld> saveWorld(AuthoringWorld world) async {
    final json = await _saveAuthoring(
      'authoring/worlds',
      world.id,
      world.toJson(),
    );
    return AuthoringWorld.fromJson(_object(json, 'world'));
  }

  @override
  Future<AuthoringTopic> saveTopic(AuthoringTopic topic) async {
    final json = await _saveAuthoring(
      'authoring/topics',
      topic.id,
      topic.toJson(),
    );
    return AuthoringTopic.fromJson(_object(json, 'topic'));
  }

  @override
  Future<AuthoringMission> saveMission(AuthoringMission mission) async {
    final json = await _saveAuthoring(
      'authoring/missions',
      mission.id,
      mission.toJson(),
    );
    return AuthoringMission.fromJson(_object(json, 'mission'));
  }

  @override
  Future<AuthoringQuestion> saveQuestion(AuthoringQuestion question) async {
    final json = await _saveAuthoring(
      'authoring/questions',
      question.id,
      question.toJson(),
    );
    return AuthoringQuestion.fromJson(_object(json, 'question'));
  }

  Future<Map<String, Object?>> _get(String path) async {
    final response = await _client.get(_baseUri.resolve(path));
    final json = _decode(response);
    _throwWhenFailed(response, json);
    return json;
  }

  Future<Map<String, Object?>> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client.post(
      _baseUri.resolve(path),
      headers: const {'content-type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );
    final json = _decode(response);
    _throwWhenFailed(response, json);
    return json;
  }

  Future<Map<String, Object?>> _saveAuthoring(
    String path,
    String? id,
    Map<String, Object?> body,
  ) {
    return id == null
        ? _post(path, body)
        : _put('$path/${Uri.encodeComponent(id)}', body);
  }

  Future<Map<String, Object?>> _put(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client.put(
      _baseUri.resolve(path),
      headers: const {'content-type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );
    final json = _decode(response);
    _throwWhenFailed(response, json);
    return json;
  }

  Map<String, Object?> _decode(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      if (value is Map<String, Object?>) return value;
      throw const FormatException('La respuesta no es un objeto JSON.');
    } on FormatException catch (error) {
      throw CatalogException(
        'invalid_server_response',
        'El servidor devolvió una respuesta inválida: ${error.message}',
      );
    }
  }

  void _throwWhenFailed(http.Response response, Map<String, Object?> json) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final error = json['error'];
    if (error is Map<String, Object?>) {
      throw CatalogException(
        error['code'] is String ? error['code']! as String : 'request_failed',
        error['message'] is String
            ? error['message']! as String
            : 'No fue posible completar la solicitud.',
      );
    }
    throw CatalogException(
      'request_failed',
      'El servidor respondió con estado ${response.statusCode}.',
    );
  }

  Map<String, Object?> _object(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! Map<String, Object?>) {
      throw CatalogException(
        'invalid_server_response',
        'El campo "$key" no contiene un objeto válido.',
      );
    }
    return value;
  }
}
