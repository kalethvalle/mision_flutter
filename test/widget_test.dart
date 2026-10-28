import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/app.dart';

import 'support/test_catalog_repository.dart';

void main() {
  testWidgets('muestra el estado inicial del mapa de mundos', (tester) async {
    final repository = TestCatalogRepository();
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Mapa de Mundos'), findsOneWidget);
    expect(find.text('Mundo 1: Fundamentos de Dart'), findsOneWidget);
    expect(find.text('Mundo 2: Layouts & Flexbox'), findsOneWidget);
    expect(find.text('QUÉ APRENDERÁS'), findsNWidgets(2));
    expect(find.text('Tipos numéricos'), findsOneWidget);
    expect(find.text('Superposición'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('BLOQUEADO'), findsOneWidget);
  });

  testWidgets('presenta la guía antes del ejercicio y respeta sus límites', (
    tester,
  ) async {
    final repository = TestCatalogRepository();
    final firstMission = repository.missionsFor('world_1').first;
    await _setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('ANTES DE COMENZAR'), findsOneWidget);
    expect(find.text('Lo que aprenderás'), findsOneWidget);
    expect(find.text('Pasos para resolver'), findsOneWidget);

    final conceptText = tester.widget<Text>(
      find.text(firstMission.learningContextParagraphs[0]),
    );
    final applicationText = tester.widget<Text>(
      find.text(firstMission.learningContextParagraphs[1]),
    );
    expect(conceptText.maxLines, 4);
    expect(applicationText.maxLines, 3);
    for (final instruction in firstMission.instructions) {
      expect(tester.widget<Text>(find.text(instruction)).maxLines, 2);
    }

    final guideTop = tester.getTopLeft(find.text('ANTES DE COMENZAR')).dy;
    final codeTop = tester.getTopLeft(find.text('[ SELECCIONA ]')).dy;
    expect(guideTop, lessThan(codeTop));

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();
    expect(find.text(firstMission.learningContextParagraphs[0]), findsNothing);
    expect(
      find.text(
        repository.missionsFor('world_1')[1].learningContextParagraphs[0],
      ),
      findsOneWidget,
    );
  });

  testWidgets('mantiene mapa y misión sin overflow en móvil', (tester) async {
    final repository = TestCatalogRepository();
    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();
    expect(find.text('ANTES DE COMENZAR'), findsOneWidget);
    expect(find.text('Lo que aprenderás'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra error visible cuando el catálogo no está disponible', (
    tester,
  ) async {
    await tester.pumpWidget(
      FlutterQuestApp(
        catalogRepository: TestCatalogRepository(
          failureMessage: 'Servidor local no disponible.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Servidor local no disponible.'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}
