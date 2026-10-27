import 'package:flutter/material.dart';

import '../../../models/mission_model.dart';

final missionFinal = MissionModel(
  id: 'w1_m2',
  worldId: 'world_1',
  worldTitle: 'Mundo 1: Fundamentos de Dart',
  missionTitle: 'Misión 2 • Inmutabilidad con final',
  description: 'El nombre del héroe no debe cambiar durante la aventura. Usa la palabra clave para declarar una variable inmutable.',
  learningContextParagraphs: const [
    'Dart permite proteger una variable contra nuevas asignaciones cuando su referencia debe permanecer estable. Esto no exige conocer el valor al compilar.',
    'El nombre del héroe recibe un valor inicial y no debe reemplazarse durante la aventura.',
  ],
  instructions: const [
    'Observa cómo se inicializa la variable nombreHeroe.',
    'Identifica que su valor no debe cambiar después.',
    'Elige la declaración que impide una segunda asignación.',
  ],
  hint: 'La declaración debe impedir una segunda asignación sin exigir un valor de compilación.',
  category: MissionCategory.dartBasics,
  targetPlaceholder: '{{ keyword }}',
  codeTemplate: [
    '{{ keyword }} nombreHeroe = "Kael";',
    '// nombreHeroe = "Otro"; // Error en compilación',
  ],
  options: const [
    MissionOption(id: 'var', label: 'var', codeSnippet: 'var'),
    MissionOption(id: 'final', label: 'final', codeSnippet: 'final'),
    MissionOption(id: 'dynamic', label: 'dynamic', codeSnippet: 'dynamic'),
  ],
  correctOptionId: 'final',
  previewBuilder: (context, selectedOptionId) {
    final bool isCorrect = selectedOptionId == 'final';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.verified_user_rounded : Icons.shield_outlined,
            color: isCorrect ? const Color(0xFF38BDF8) : Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isCorrect ? 'Héroe: Kael (Inmutable)' : 'Variable mutable',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  },
);
