import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../application/assessment/assessment_service.dart';
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
      ..get('/api/v1/assessments/<id>/result', _result)
      ..get('/api/v1/reports', _report);
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
}
