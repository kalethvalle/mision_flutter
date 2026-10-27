import 'package:flutter/material.dart';

import '../../../models/mission_model.dart';

final missionNullSafety = MissionModel(
  id: 'w1_m5',
  worldId: 'world_1',
  worldTitle: 'Mundo 1: Fundamentos de Dart',
  missionTitle: 'Misión 5 • Null Safety (?)',
  description: 'Un arma opcional puede ser nula si el héroe no tiene nada equipado. Marca el tipo de dato como anulable.',
  learningContextParagraphs: const [
    'Los tipos de Dart no aceptan null de manera predeterminada. Cuando la ausencia de un valor es válida, la declaración debe expresarlo.',
    'El héroe puede tener un arma de texto o no tener ninguna, por lo que ambos estados deben ser válidos.',
  ],
  instructions: const [
    'Observa que armaEquipada comienza con el valor null.',
    'Conserva el tipo de texto para cuando exista un arma.',
    'Elige la variante que permita valor y ausencia de valor.',
  ],
  hint: 'La declaración debe permitir tanto texto como ausencia de valor.',
  category: MissionCategory.dartBasics,
  targetPlaceholder: '{{ nullableType }}',
  codeTemplate: [
    '{{ nullableType }} armaEquipada = null;',
    'print(armaEquipada ?? "Sin arma");',
  ],
  options: const [
    MissionOption(id: 'String?', label: 'String?', codeSnippet: 'String?'),
    MissionOption(id: 'String!', label: 'String!', codeSnippet: 'String!'),
    MissionOption(id: 'String', label: 'String', codeSnippet: 'String'),
  ],
  correctOptionId: 'String?',
  previewBuilder: (context, selectedOptionId) {
    final bool isCorrect = selectedOptionId == 'String?';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_outline : Icons.block_rounded,
            color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isCorrect
                ? 'Estado: Sin arma (Seguro contra Null)'
                : 'Error: No acepta null',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCorrect ? const Color(0xFF10B981) : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  },
);
