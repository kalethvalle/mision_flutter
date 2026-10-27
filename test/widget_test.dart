import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/app.dart';

void main() {
  testWidgets('muestra el estado inicial del mapa de mundos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FlutterQuestApp());

    expect(find.text('Mapa de Mundos'), findsOneWidget);
    expect(find.text('Mundo 1: Fundamentos de Dart'), findsOneWidget);
    expect(find.text('Mundo 2: Layouts & Flexbox'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
    expect(find.text('BLOQUEADO'), findsOneWidget);
  });
}
