import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'core/repositories/http_catalog_repository.dart';

void main() {
  final apiBaseUri = _apiBaseUri();
  runApp(
    FlutterQuestApp(
      catalogRepository: HttpCatalogRepository(
        client: http.Client(),
        baseUri: apiBaseUri,
      ),
    ),
  );
}

Uri _apiBaseUri() {
  const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (configuredBaseUrl.isNotEmpty) {
    final uri = Uri.parse(configuredBaseUrl);
    return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
  }
  return Uri.base.resolve('/api/v1/');
}
