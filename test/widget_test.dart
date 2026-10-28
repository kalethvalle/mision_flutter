import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/app.dart';
import 'package:mision_flutter/core/store/world/syntax_dart/syntax_dart_world.dart';

void main() {
  testWidgets('muestra el estado inicial del mapa de mundos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlutterQuestApp());

    expect(find.text('Mapa de Mundos'), findsOneWidget);
    expect(find.text('Mundo 1: Fundamentos de Dart'), findsOneWidget);
    expect(find.text('Mundo 2: Layouts & Flexbox'), findsOneWidget);
    expect(find.text('QUÉ APRENDERÁS'), findsNWidgets(2));
    expect(
      find.text(
        'Tipos y variables, valores inmutables, funciones breves, listas tipadas y null safety.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Distribución horizontal y vertical, padding uniforme y superposición con Stack y Positioned.',
      ),
      findsOneWidget,
    );
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('BLOQUEADO'), findsOneWidget);
  });

  testWidgets('presenta la guía antes del ejercicio y respeta sus límites', (
    WidgetTester tester,
  ) async {
    await _setViewport(tester, const Size(1200, 900));
    await tester.pumpWidget(const FlutterQuestApp());

    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    final firstMission = syntaxDartMissions.first;
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
      final instructionText = tester.widget<Text>(find.text(instruction));
      expect(instructionText.maxLines, 2);
    }

    final guideTop = tester.getTopLeft(find.text('ANTES DE COMENZAR')).dy;
    final codeTop = tester.getTopLeft(find.text('[ SELECCIONA ]')).dy;
    expect(guideTop, lessThan(codeTop));

    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.text(firstMission.learningContextParagraphs[0]), findsNothing);
    expect(
      find.text(syntaxDartMissions[1].learningContextParagraphs[0]),
      findsOneWidget,
    );
  });

  testWidgets('mantiene mapa y misión sin overflow en móvil', (
    WidgetTester tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(const FlutterQuestApp());

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(find.text('ANTES DE COMENZAR'), findsOneWidget);
    expect(find.text('Lo que aprenderás'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}
