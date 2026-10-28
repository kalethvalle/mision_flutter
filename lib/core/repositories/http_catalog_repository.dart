import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/answer_check_result.dart';
import '../models/mission_model.dart';
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
    String optionId,
  ) async {
    final response = await _client.post(
      _baseUri.resolve('missions/${Uri.encodeComponent(missionId)}/check'),
      headers: const {'content-type': 'application/json; charset=utf-8'},
      body: jsonEncode({'optionId': optionId}),
    );
    final json = _decode(response);
    _throwWhenFailed(response, json);
    return AnswerCheckResult.fromJson(_object(json, 'result'));
  }

  Future<Map<String, Object?>> _get(String path) async {
    final response = await _client.get(_baseUri.resolve(path));
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
