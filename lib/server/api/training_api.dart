import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../application/progress/progress_service.dart';
import '../../core/repositories/catalog_repository.dart';
import 'api_security.dart';
import 'api_support.dart';

class TrainingApi {
  factory TrainingApi({
    required ProgressService progressService,
    required ApiSecurity security,
  }) => TrainingApi._(progressService, security);

  TrainingApi._(this._progressService, this._security) {
    _router
      ..get('/api/v1/progress', _progress)
      ..post('/api/v1/missions/<missionId>/check', _checkAnswer);
  }

  final ProgressService _progressService;
  final ApiSecurity _security;
  final Router _router = Router();

  Handler get handler => _router.call;

  Future<Response> _progress(Request request) => guardApi(() async {
    final user = await _security.requireUser(request);
    final progress = await _progressService.load(user);
    return jsonResponse(200, {'progress': progress.toJson()});
  });

  Future<Response> _checkAnswer(Request request, String missionId) {
    return guardApi(() async {
      final user = await _security.requireUser(request);
      final body = await readJsonObject(request);
      final optionId = body['optionId'];
      final hintUsed = body['hintUsed'];
      if (optionId is! String || hintUsed is! bool) {
        throw const CatalogException(
          'invalid_option',
          'La opción y el indicador de pista son obligatorios.',
        );
      }
      final result = await _progressService.checkAnswer(
        user: user,
        missionId: missionId,
        optionId: optionId,
        hintUsed: hintUsed,
      );
      return jsonResponse(200, {'result': result.toJson()});
    });
  }
}
