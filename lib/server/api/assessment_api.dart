import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../application/assessment/assessment_service.dart';
import '../../core/models/assessment_model.dart';
import '../../core/repositories/catalog_repository.dart';
import 'api_security.dart';
import 'api_support.dart';

class AssessmentApi {
  factory AssessmentApi({
    required AssessmentService assessmentService,
    required ApiSecurity security,
  }) => AssessmentApi._(assessmentService, security);

  AssessmentApi._(this._assessmentService, this._security) {
    _router
      ..get('/api/v1/assessments', _overview)
      ..post('/api/v1/worlds/<worldId>/assessments', _start)
      ..get('/api/v1/assessments/<id>', _attempt)
      ..post('/api/v1/assessments/<id>/submit', _submit)
      ..patch('/api/v1/assessments/<id>/draft-answers', _draftAnswers)
      ..post('/api/v1/assessments/<id>/incidents', _incident)
      ..get('/api/v1/assessments/<id>/result', _result)
      ..get('/api/v1/reports', _report)
      ..get('/api/v1/reports/assessments/<id>', _detailReport)
      ..get('/api/v1/assessment-sessions', _sessions)
      ..post('/api/v1/assessment-sessions', _openSession)
      ..patch('/api/v1/assessment-sessions/<worldId>/settings', _settings)
      ..post('/api/v1/assessment-sessions/<id>/close', _closeSession)
      ..post('/api/v1/assessments/<id>/reactivate', _reactivate)
      ..get('/api/v1/assessment-sessions/<id>/events', _events);
  }

  final AssessmentService _assessmentService;
  final ApiSecurity _security;
  final Router _router = Router();

  Handler get handler => _router.call;

  Future<Response> _overview(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final overview = await _assessmentService.overview(actor);
    return jsonResponse(200, {'overview': overview.toJson()});
  });

  Future<Response> _start(Request request, String worldId) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final attempt = await _assessmentService.start(actor, worldId);
        return jsonResponse(201, {'attempt': attempt.toJson()});
      });

  Future<Response> _attempt(Request request, String id) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final attempt = await _assessmentService.loadAttempt(actor, id);
    return jsonResponse(200, {'attempt': attempt.toJson()});
  });

  Future<Response> _submit(Request request, String id) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final body = await readJsonObject(request);
    final rawAnswers = body['answers'];
    if (rawAnswers is! List<Object?>) {
      throw const CatalogException(
        'invalid_answers',
        'El campo answers debe ser una lista.',
      );
    }
    final answers = <String, List<String>>{};
    for (final raw in rawAnswers) {
      if (raw is! Map<String, Object?> ||
          raw['questionId'] is! String ||
          raw['optionIds'] is! List<Object?> ||
          (raw['optionIds']! as List<Object?>).any((item) => item is! String)) {
        throw const CatalogException(
          'invalid_answers',
          'Cada respuesta debe incluir questionId y optionIds válidos.',
        );
      }
      final questionId = raw['questionId']! as String;
      if (answers.containsKey(questionId)) {
        throw const CatalogException(
          'invalid_answers',
          'Cada pregunta debe aparecer una sola vez.',
        );
      }
      answers[questionId] = (raw['optionIds']! as List<Object?>).cast<String>();
    }
    final result = await _assessmentService.submit(actor, id, answers);
    return jsonResponse(200, {'result': result.toJson()});
  });

  Future<Response> _draftAnswers(Request request, String id) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final body = await readJsonObject(request);
        await _assessmentService.saveDraftAnswers(
          actor,
          id,
          _answersFromBody(body),
        );
        return jsonResponse(200, {'ok': true});
      });

  Future<Response> _incident(Request request, String id) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final body = await readJsonObject(request);
    final type = body['type'];
    final message = body['message'];
    if (type is! String || message is! String) {
      throw const CatalogException(
        'invalid_json',
        'El incidente requiere type y message.',
      );
    }
    final attempt = await _assessmentService.recordIncident(
      actor,
      id,
      type: type,
      message: message,
    );
    return jsonResponse(200, {'attempt': attempt.toJson()});
  });

  Future<Response> _result(Request request, String id) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final result = await _assessmentService.loadResult(actor, id);
    return jsonResponse(200, {'result': result.toJson()});
  });

  Future<Response> _report(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final query = request.url.queryParameters;
    final report = await _assessmentService.report(
      actor,
      studentId: query['studentId'],
      worldId: query['worldId'],
      topicId: query['topicId'],
    );
    return jsonResponse(200, {'report': report.toJson()});
  });

  Future<Response> _detailReport(Request request, String id) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final report = await _assessmentService.detailReport(actor, id);
        return jsonResponse(200, {'report': report.toJson()});
      });

  Future<Response> _sessions(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final overview = await _assessmentService.sessionOverview(actor);
    return jsonResponse(200, {'overview': overview.toJson()});
  });

  Future<Response> _openSession(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final body = await readJsonObject(request);
    final worldId = body['worldId'];
    if (worldId is! String) {
      throw const CatalogException(
        'invalid_world_id',
        'El mundo es obligatorio.',
      );
    }
    final session = await _assessmentService.openSession(actor, worldId);
    return jsonResponse(201, {'session': session.toJson()});
  });

  Future<Response> _settings(Request request, String worldId) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final body = await readJsonObject(request);
        final settings = AssessmentWorldSettings(
          worldId: worldId,
          durationMinutes: _int(body, 'durationMinutes'),
          fullscreenRequired: _bool(body, 'fullscreenRequired'),
          maxIncidents: _int(body, 'maxIncidents'),
          returnGraceSeconds: _int(body, 'returnGraceSeconds'),
          strictMode: _bool(body, 'strictMode'),
        );
        final saved = await _assessmentService.saveSettings(actor, settings);
        return jsonResponse(200, {'settings': saved.toJson()});
      });

  Future<Response> _closeSession(Request request, String id) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final session = await _assessmentService.closeSession(actor, id);
        return jsonResponse(200, {'session': session.toJson()});
      });

  Future<Response> _reactivate(Request request, String id) =>
      guardApi(() async {
        final actor = await _security.requireUser(request);
        final body = await readJsonObject(request);
        final reason = body['reason'];
        if (reason is! String) {
          throw const CatalogException(
            'invalid_json',
            'La reactivación requiere un motivo.',
          );
        }
        final session = await _assessmentService.reactivateAttempt(
          actor,
          id,
          reason: reason,
        );
        return jsonResponse(200, {'session': session.toJson()});
      });

  Future<Response> _events(Request request, String id) async {
    try {
      final actor = await _security.requireUser(request);
      final stream = _assessmentService
          .streamSessionEvents(actor, id)
          .map((event) => 'data: ${jsonEncode(event.toJson())}\n\n');
      return Response.ok(
        stream,
        headers: const {
          'content-type': 'text/event-stream; charset=utf-8',
          'cache-control': 'no-cache',
        },
      );
    } on Object {
      return guardApi(() async {
        final actor = await _security.requireUser(request);
        _assessmentService.streamSessionEvents(actor, id);
        return jsonResponse(200, const {});
      });
    }
  }

  Map<String, List<String>> _answersFromBody(Map<String, Object?> body) {
    final rawAnswers = body['answers'];
    if (rawAnswers is! List<Object?>) {
      throw const CatalogException(
        'invalid_answers',
        'El campo answers debe ser una lista.',
      );
    }
    final answers = <String, List<String>>{};
    for (final raw in rawAnswers) {
      if (raw is! Map<String, Object?> ||
          raw['questionId'] is! String ||
          raw['optionIds'] is! List<Object?> ||
          (raw['optionIds']! as List<Object?>).any((item) => item is! String)) {
        throw const CatalogException(
          'invalid_answers',
          'Cada respuesta debe incluir questionId y optionIds válidos.',
        );
      }
      answers[raw['questionId']! as String] =
          (raw['optionIds']! as List<Object?>).cast<String>();
    }
    return answers;
  }

  int _int(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value is int) return value;
    throw CatalogException('invalid_json', 'El campo $key debe ser entero.');
  }

  bool _bool(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value is bool) return value;
    throw CatalogException('invalid_json', 'El campo $key debe ser booleano.');
  }
}
