import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';

import 'api/catalog_api.dart';

Handler createServerHandler({
  required CatalogApi api,
  required String webRoot,
}) {
  final staticHandler = createStaticHandler(
    webRoot,
    defaultDocument: 'index.html',
  );

  Future<Response> handler(Request request) async {
    if (request.url.path.startsWith('api/')) {
      return api.handler(request);
    }

    final indexFile = File('$webRoot/index.html');
    if (!indexFile.existsSync()) {
      return Response(
        503,
        body: 'No se encontró build/web. Ejecuta "flutter build web".',
        headers: const {'content-type': 'text/plain; charset=utf-8'},
      );
    }

    final response = await staticHandler(request);
    if (response.statusCode != 404) return response;
    return Response.ok(
      indexFile.openRead(),
      headers: const {'content-type': 'text/html; charset=utf-8'},
    );
  }

  return const Pipeline().addMiddleware(logRequests()).addHandler(handler);
}
