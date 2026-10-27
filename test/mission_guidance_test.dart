import 'package:flutter_test/flutter_test.dart';
import 'package:mision_flutter/core/models/mission_model.dart';
import 'package:mision_flutter/core/store/world/layout/layout_world.dart';
import 'package:mision_flutter/core/store/world/syntax_dart/syntax_dart_world.dart';

void main() {
  final missions = <MissionModel>[...syntaxDartMissions, ...layoutMissions];

  test('todas las misiones incluyen una guía pedagógica completa', () {
    expect(missions, hasLength(9));
    expect(missions.map((mission) => mission.id).toSet(), hasLength(9));

    for (final mission in missions) {
      expect(
        mission.learningContextParagraphs,
        hasLength(2),
        reason: mission.id,
      );
      expect(
        mission.learningContextParagraphs.every(
          (paragraph) =>
              paragraph.trim().isNotEmpty && !paragraph.contains('\n'),
        ),
        isTrue,
        reason: mission.id,
      );
      expect(mission.instructions, hasLength(3), reason: mission.id);
      expect(
        mission.instructions.every(
          (instruction) =>
              instruction.trim().isNotEmpty && !instruction.contains('\n'),
        ),
        isTrue,
        reason: mission.id,
      );
      expect(mission.hint.trim(), isNotEmpty, reason: mission.id);

      final correctOption = mission.options.firstWhere(
        (option) => option.id == mission.correctOptionId,
      );
      expect(
        mission.hint,
        isNot(contains(correctOption.codeSnippet)),
        reason: 'La pista de ${mission.id} revela la respuesta.',
      );
    }
  });

  test('el contenido respeta presupuestos editoriales breves', () {
    for (final mission in missions) {
      expect(
        mission.learningContextParagraphs[0].length,
        lessThanOrEqualTo(180),
        reason: '${mission.id}: primer párrafo',
      );
      expect(
        mission.learningContextParagraphs[1].length,
        lessThanOrEqualTo(120),
        reason: '${mission.id}: segundo párrafo',
      );

      for (var index = 0; index < mission.instructions.length; index++) {
        expect(
          mission.instructions[index].length,
          lessThanOrEqualTo(90),
          reason: '${mission.id}: instrucción ${index + 1}',
        );
      }
    }
  });
}
