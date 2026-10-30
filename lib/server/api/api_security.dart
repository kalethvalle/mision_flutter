import 'package:shelf/shelf.dart';

import '../../application/identity/identity_service.dart';
import '../../core/models/user_model.dart';
import '../../core/repositories/catalog_repository.dart';

class ApiSecurity {
  const ApiSecurity(this._identityService);

  static const cookieName = 'fq_session';

  final IdentityService _identityService;

  String? tokenFromRequest(Request request) {
    final cookie = request.headers['cookie'];
    if (cookie == null) return null;
    for (final part in cookie.split(';')) {
      final separator = part.indexOf('=');
      if (separator < 0) continue;
      final name = part.substring(0, separator).trim();
      if (name == cookieName) {
        return Uri.decodeComponent(part.substring(separator + 1).trim());
      }
    }
    return null;
  }

  Future<UserModel?> optionalUser(Request request) {
    return _identityService.authenticate(tokenFromRequest(request));
  }

  Future<UserModel> requireUser(Request request) async {
    final user = await optionalUser(request);
    if (user == null) {
      throw const CatalogException(
        'unauthorized',
        'Debes iniciar sesión para continuar.',
      );
    }
    return user;
  }
}
