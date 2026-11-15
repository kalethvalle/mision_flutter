import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../application/analytics/analytics_service.dart';
import 'api_security.dart';
import 'api_support.dart';

class AnalyticsApi {
  factory AnalyticsApi({
    required AnalyticsService analyticsService,
    required ApiSecurity security,
  }) => AnalyticsApi._(analyticsService, security);

  AnalyticsApi._(this._analyticsService, this._security) {
    _router
      ..get('/api/v1/analytics/dashboard', _dashboard)
      ..post('/api/v1/analytics/refresh', _refresh);
  }

  final AnalyticsService _analyticsService;
  final ApiSecurity _security;
  final Router _router = Router();

  Handler get handler => _router.call;

  Future<Response> _dashboard(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final dashboard = await _analyticsService.dashboard(actor);
    return jsonResponse(200, {'dashboard': dashboard.toJson()});
  });

  Future<Response> _refresh(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final dashboard = await _analyticsService.refresh(actor);
    return jsonResponse(200, {'dashboard': dashboard.toJson()});
  });
}
