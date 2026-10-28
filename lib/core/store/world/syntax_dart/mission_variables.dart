import 'package:flutter/material.dart';

import '../../../models/mission_model.dart';

final missionVariables = MissionModel(
  id: 'w1_m1',
  worldId: 'world_1',
  worldTitle: 'Mundo 1: Fundamentos de Dart',
  missionTitle: 'Misión 1 • Variables y Tipos Primitivos',
  description: 'Selecciona el tipo de dato adecuado para declarar la vida inicial (número entero) del personaje.',
  learningContextParagraphs: const [
    'En Dart, el tipo define qué valores puede almacenar una variable y qué operaciones admite. Los números pueden ser enteros o incluir decimales.',
    'La vida del héroe vale 100, por lo que debe representarse como un número sin parte decimal.',
  ],
  instructions: const [
    'Observa el valor asignado a vidaHeroe y la vista previa.',
    'Decide si 100 contiene una parte decimal.',
    'Compara las opciones y elige el tipo para números enteros.',
  ],
  hint: 'Compara un valor sin decimal con uno que sí tiene parte decimal.',
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
