import 'package:shelf/shelf.dart';

import 'catalog_api.dart';
import 'authoring_api.dart';
import 'identity_api.dart';
import 'training_api.dart';

Handler createApiHandler({
  required IdentityApi identityApi,
  required CatalogApi catalogApi,
  required TrainingApi trainingApi,
  required AuthoringApi authoringApi,
}) {
  return Cascade()
      .add(identityApi.handler)
      .add(catalogApi.handler)
      .add(trainingApi.handler)
      .add(authoringApi.handler)
      .add((request) => Response.notFound('Ruta API no encontrada.'))
      .handler;
}
