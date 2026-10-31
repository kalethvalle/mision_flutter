import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'core/repositories/http_catalog_repository.dart';

void main() {
  final apiBaseUri = Uri.base.resolve('/api/v1/');
  runApp(
    FlutterQuestApp(
      catalogRepository: HttpCatalogRepository(
        client: http.Client(),
        baseUri: apiBaseUri,
      ),
    ),
  );
}
