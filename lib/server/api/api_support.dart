import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../core/repositories/catalog_repository.dart';

Response jsonResponse(
  int status,
  Map<String, Object?> body, {
  Map<String, String>? headers,
}) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
  );
}

Response errorResponse(int status, String code, String message) {
  return jsonResponse(status, {
    'error': {'code': code, 'message': message},
  });
}

Future<Map<String, Object?>> readJsonObject(Request request) async {
  try {
    final value = jsonDecode(await request.readAsString());
    if (value is Map<String, Object?>) return value;
    throw const FormatException();
  } on FormatException {
    throw const CatalogException(
      'invalid_json',
      'El cuerpo debe ser un objeto JSON válido.',
    );
  }
}

Future<Response> guardApi(Future<Response> Function() operation) async {
  try {
    return await operation();
  } on CatalogException catch (error) {
    final status = switch (error.code) {
      'unauthorized' || 'session_expired' => 401,
      'forbidden' => 403,
      'mission_not_found' => 404,
      'bootstrap_completed' || 'username_taken' || 'mission_locked' => 409,
      'invalid_credentials' ||
      'invalid_option' ||
      'invalid_json' ||
      'invalid_world_id' ||
      'invalid_username' ||
      'invalid_display_name' ||
      'invalid_password' => 400,
      _ => 422,
    };
    return errorResponse(status, error.code, error.message);
  } on Object {
    return errorResponse(
      500,
      'internal_error',
      'No fue posible completar la solicitud.',
    );
  }
}
