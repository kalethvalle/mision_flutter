import 'package:flutter/material.dart';
import '../../../models/mission_model.dart';

final missionVariables = MissionModel(
  id: 'w1_m1',
  worldId: 'world_1',
  worldTitle: 'Mundo 1: Fundamentos de Dart',
  missionTitle: 'Misión 1 • Variables y Tipos Primitivos',
  description:
      'Selecciona el tipo de dato adecuado para declarar la vida inicial (número entero) del personaje.',
  hint: 'Usa "int" para números enteros. "double" es para decimales y "String" para texto.',
  category: MissionCategory.dartBasics,
  targetPlaceholder: '{{ type }}',
  codeTemplate: [
    '{{ type }} vidaHeroe = 100;',
    'print("Vida inicial: \$vidaHeroe HP");',
  ],
  options: const [
    MissionOption(id: 'String', label: 'String', codeSnippet: 'String'),
    MissionOption(id: 'int', label: 'int', codeSnippet: 'int'),
    MissionOption(id: 'double', label: 'double', codeSnippet: 'double'),
  ],
  correctOptionId: 'int',
  previewBuilder: (context, selectedOptionId) {
    final bool isCorrect = selectedOptionId == 'int';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_rounded,
            color: isCorrect ? Colors.redAccent : Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isCorrect ? 'Vida: 100 HP' : 'Tipo incorrecto',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.white : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  },
);