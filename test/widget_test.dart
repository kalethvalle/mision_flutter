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
    expect(find.text('QUÉ APRENDERÁS'), findsOneWidget);
    expect(find.text('Tipos numéricos'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Mundo 2: Layouts & Flexbox'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mundo 2: Layouts & Flexbox'), findsOneWidget);
    expect(find.text('QUÉ APRENDERÁS'), findsOneWidget);
    expect(find.text('Superposición'), findsOneWidget);
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

    final correctOptionId = repository.correctOptionIds[firstMission.id]!;
    final correctOption = firstMission.options.singleWhere(
      (option) => option.id == correctOptionId,
    );
    await tester.ensureVisible(find.text(correctOption.label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(correctOption.label));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('PROBAR CÓDIGO'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PROBAR CÓDIGO'));
    await tester.pumpAndSettle();
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

  testWidgets('crea docente y estudiante antes de iniciar el entrenamiento', (
    tester,
  ) async {
    final repository = TestCatalogRepository(bootstrapRequired: true);
    await _setViewport(tester, const Size(900, 900));
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Crear docente inicial'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Docente Principal',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'teacher');
    await tester.enterText(find.byType(TextFormField).at(2), 'teacher1234');
    await tester.tap(find.text('CREAR DOCENTE'));
    await tester.pumpAndSettle();

    expect(find.text('Panel docente • Docente Principal'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Ana Estudiante');
    await tester.enterText(find.byType(TextFormField).at(1), 'ana');
    await tester.enterText(find.byType(TextFormField).at(2), 'student1234');
    await tester.ensureVisible(find.text('CREAR ESTUDIANTE'));
    await tester.tap(find.text('CREAR ESTUDIANTE'));
    await tester.pumpAndSettle();
    expect(find.text('Ana Estudiante'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'student1234');
    await tester.tap(find.text('INGRESAR'));
    await tester.pumpAndSettle();

    expect(find.text('Mapa de Mundos'), findsOneWidget);
    expect(find.textContaining('Ana Estudiante'), findsOneWidget);
  });

  testWidgets('docente abre autoría y conserva un borrador de pregunta', (
    tester,
  ) async {
    final repository = TestCatalogRepository(authenticatedUser: testTeacher);
    await _setViewport(tester, const Size(1100, 900));
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('ESTUDIANTES'), findsOneWidget);
    await tester.tap(find.text('CONTENIDO'));
    await tester.pumpAndSettle();
    expect(find.text('Editor de contenido'), findsOneWidget);
    expect(find.text('NUEVO MUNDO'), findsOneWidget);
    expect(find.text('NUEVA MISIÓN'), findsOneWidget);

    await tester.tap(find.text('PREGUNTAS'));
    await tester.pumpAndSettle();
    expect(find.text('Banco de preguntas'), findsOneWidget);
    await tester.tap(find.text('NUEVA PREGUNTA'));
    await tester.pumpAndSettle();
    expect(find.text('Nueva pregunta'), findsOneWidget);
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(find.text('Preguntas (1)'), findsOneWidget);
    expect(find.text('Pregunta sin enunciado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor docente se adapta a pantalla móvil', (tester) async {
    final repository = TestCatalogRepository(authenticatedUser: testTeacher);
    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('CONTENIDO'));
    await tester.pumpAndSettle();
    expect(find.text('Editor de contenido'), findsOneWidget);
    expect(find.text('NUEVO MUNDO'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('NUEVO MUNDO'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo mundo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('estudiante presenta, recibe resultado y conserva historial', (
    tester,
  ) async {
    final repository = TestCatalogRepository()..addPublishedQuestion();
    repository.completedMissionIds.addAll(
      repository.missionsFor('world_1').map((mission) => mission.id),
    );
    await _setViewport(tester, const Size(900, 900));
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    expect(find.text('JEFE FINAL'), findsNWidgets(2));
    await tester.tap(find.text('JEFE FINAL').first);
    await tester.pumpAndSettle();
    expect(find.text('Pregunta de prueba'), findsOneWidget);
    expect(find.text('Explicación de prueba.'), findsNothing);

    await tester.tap(find.text('Correcta'));
    await tester.tap(find.text('ENTREGAR PARCIAL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ENTREGAR'));
    await tester.pumpAndSettle();
    expect(find.text('¡JEFE SUPERADO!'), findsOneWidget);
    expect(find.textContaining('100/100'), findsWidgets);
    expect(find.text('Explicación de prueba.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Historial de parciales'));
    await tester.pumpAndSettle();
    expect(find.text('Historial de parciales'), findsOneWidget);
    expect(find.text('100/100 • APROBADO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('docente consulta pestaña de resultados', (tester) async {
    final repository = TestCatalogRepository(authenticatedUser: testTeacher);
    await _setViewport(tester, const Size(1100, 900));
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('RESULTADOS'));
    await tester.pumpAndSettle();
    expect(find.text('Resultados de aprendizaje'), findsOneWidget);
    expect(find.textContaining('Entrenamiento (0)'), findsOneWidget);
    expect(find.textContaining('Parciales (0)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('parcial se adapta a pantalla móvil', (tester) async {
    final repository = TestCatalogRepository()..addPublishedQuestion();
    repository.completedMissionIds.addAll(
      repository.missionsFor('world_1').map((mission) => mission.id),
    );
    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(FlutterQuestApp(catalogRepository: repository));
    await tester.pumpAndSettle();

    final bossButton = find.widgetWithText(OutlinedButton, 'JEFE FINAL').first;
    await tester.scrollUntilVisible(
      bossButton,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(bossButton);
    await tester.pumpAndSettle();
    await tester.tap(bossButton);
    await tester.pumpAndSettle();
    expect(find.text('Pregunta de prueba'), findsOneWidget);
    expect(find.text('ENTREGAR PARCIAL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}
