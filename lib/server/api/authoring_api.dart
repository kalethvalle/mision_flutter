import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../application/authoring/authoring_service.dart';
import '../../core/models/authoring_model.dart';
import 'api_security.dart';
import 'api_support.dart';

class AuthoringApi {
  factory AuthoringApi({
    required AuthoringService authoringService,
    required ApiSecurity security,
  }) => AuthoringApi._(authoringService, security);

  AuthoringApi._(this._authoringService, this._security) {
    _router
      ..get('/api/v1/authoring', _catalog)
      ..post('/api/v1/authoring/worlds', _createWorld)
      ..put('/api/v1/authoring/worlds/<id>', _updateWorld)
      ..post('/api/v1/authoring/topics', _createTopic)
      ..put('/api/v1/authoring/topics/<id>', _updateTopic)
      ..post('/api/v1/authoring/missions', _createMission)
      ..put('/api/v1/authoring/missions/<id>', _updateMission)
      ..post('/api/v1/authoring/questions', _createQuestion)
      ..put('/api/v1/authoring/questions/<id>', _updateQuestion);
  }

  final AuthoringService _authoringService;
  final ApiSecurity _security;
  final Router _router = Router();

  Handler get handler => _router.call;

  Future<Response> _catalog(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final catalog = await _authoringService.load(actor);
    return jsonResponse(200, {'catalog': catalog.toJson()});
  });

  Future<Response> _createWorld(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final world = AuthoringWorld.fromJson(await readJsonObject(request));
    final saved = await _authoringService.saveWorld(actor, world);
    return jsonResponse(201, {'world': saved.toJson()});
  });

  Future<Response> _updateWorld(Request request, String id) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final body = await readJsonObject(request)
          ..['id'] = id;
        final saved = await _authoringService.saveWorld(
          actor,
          AuthoringWorld.fromJson(body),
        );
        return jsonResponse(200, {'world': saved.toJson()});
      });

  Future<Response> _createTopic(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final saved = await _authoringService.saveTopic(
      actor,
      AuthoringTopic.fromJson(await readJsonObject(request)),
    );
    return jsonResponse(201, {'topic': saved.toJson()});
  });

  Future<Response> _updateTopic(Request request, String id) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final body = await readJsonObject(request)
          ..['id'] = id;
        final saved = await _authoringService.saveTopic(
          actor,
          AuthoringTopic.fromJson(body),
        );
        return jsonResponse(200, {'topic': saved.toJson()});
      });

  Future<Response> _createMission(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final saved = await _authoringService.saveMission(
      actor,
      AuthoringMission.fromJson(await readJsonObject(request)),
    );
    return jsonResponse(201, {'mission': saved.toJson()});
  });

  Future<Response> _updateMission(Request request, String id) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final body = await readJsonObject(request)
          ..['id'] = id;
        final saved = await _authoringService.saveMission(
          actor,
          AuthoringMission.fromJson(body),
        );
        return jsonResponse(200, {'mission': saved.toJson()});
      });

  Future<Response> _createQuestion(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final saved = await _authoringService.saveQuestion(
      actor,
      AuthoringQuestion.fromJson(await readJsonObject(request)),
    );
    return jsonResponse(201, {'question': saved.toJson()});
  });

  Future<Response> _updateQuestion(Request request, String id) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final body = await readJsonObject(request)
          ..['id'] = id;
        final saved = await _authoringService.saveQuestion(
          actor,
          AuthoringQuestion.fromJson(body),
        );
        return jsonResponse(200, {'question': saved.toJson()});
      });
}
