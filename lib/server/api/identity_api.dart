import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../application/identity/identity_service.dart';
import '../../core/repositories/catalog_repository.dart';
import 'api_security.dart';
import 'api_support.dart';

class IdentityApi {
  factory IdentityApi({
    required IdentityService identityService,
    required ApiSecurity security,
  }) => IdentityApi._(identityService, security);

  IdentityApi._(this._identityService, this._security) {
    _router
      ..get('/api/v1/auth/status', _status)
      ..post('/api/v1/auth/bootstrap', _bootstrap)
      ..post('/api/v1/auth/login', _login)
      ..post('/api/v1/auth/logout', _logout)
      ..get('/api/v1/auth/me', _me)
      ..get('/api/v1/users', _users)
      ..post('/api/v1/users', _createStudent);
  }

  final IdentityService _identityService;
  final ApiSecurity _security;
  final Router _router = Router();

  Handler get handler => _router.call;

  Future<Response> _status(Request request) => guardApi(() async {
    final user = await _security.optionalUser(request);
    return jsonResponse(200, {
      'bootstrapRequired': await _identityService.isBootstrapRequired(),
      'user': user?.toJson(),
    });
  });

  Future<Response> _bootstrap(Request request) => guardApi(() async {
    final body = await readJsonObject(request);
    final session = await _identityService.bootstrapTeacher(
      username: _string(body, 'username'),
      displayName: _string(body, 'displayName'),
      password: _string(body, 'password'),
    );
    return _sessionResponse(201, session);
  });

  Future<Response> _login(Request request) => guardApi(() async {
    final body = await readJsonObject(request);
    final session = await _identityService.login(
      username: _string(body, 'username'),
      password: _string(body, 'password'),
    );
    return _sessionResponse(200, session);
  });

  Future<Response> _logout(Request request) => guardApi(() async {
    await _security.requireUser(request);
    await _identityService.logout(_security.tokenFromRequest(request));
    return jsonResponse(
      200,
      {'loggedOut': true},
      headers: {'set-cookie': _clearCookie()},
    );
  });

  Future<Response> _me(Request request) => guardApi(() async {
    final user = await _security.requireUser(request);
    return jsonResponse(200, {'user': user.toJson()});
  });

  Future<Response> _users(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final users = await _identityService.listUsers(actor);
    return jsonResponse(200, {
      'users': users.map((user) => user.toJson()).toList(),
    });
  });

  Future<Response> _createStudent(Request request) => guardApi(() async {
    final actor = await _security.requireUser(request);
    final body = await readJsonObject(request);
    final user = await _identityService.createStudent(
      actor: actor,
      username: _string(body, 'username'),
      displayName: _string(body, 'displayName'),
      password: _string(body, 'password'),
    );
    return jsonResponse(201, {'user': user.toJson()});
  });

  Response _sessionResponse(int status, AuthSession session) {
    return jsonResponse(
      status,
      {'user': session.user.toJson()},
      headers: {'set-cookie': _sessionCookie(session)},
    );
  }

  String _sessionCookie(AuthSession session) {
    final maxAge = session.expiresAt
        .difference(DateTime.now().toUtc())
        .inSeconds
        .clamp(0, 12 * 60 * 60);
    return '${ApiSecurity.cookieName}=${Uri.encodeComponent(session.token)}; '
        'HttpOnly; SameSite=Strict; Path=/; Max-Age=$maxAge; '
        'Expires=${HttpDate.format(session.expiresAt.toUtc())}';
  }

  String _clearCookie() {
    return '${ApiSecurity.cookieName}=; HttpOnly; SameSite=Strict; Path=/; '
        'Max-Age=0; Expires=Thu, 01 Jan 1970 00:00:00 GMT';
  }

  String _string(Map<String, Object?> body, String key) {
    final value = body[key];
    if (value is! String) {
      throw CatalogException('invalid_json', 'El campo "$key" debe ser texto.');
    }
    return value;
  }
}
