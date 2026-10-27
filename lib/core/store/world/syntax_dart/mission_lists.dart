import 'package:flutter/material.dart';

import '../../../models/mission_model.dart';

final missionLists = MissionModel(
  id: 'w1_m4',
  worldId: 'world_1',
  worldTitle: 'Mundo 1: Fundamentos de Dart',
  missionTitle: 'Misión 4 • Inventario con Listas',
  description: 'Declara la lista genérica de objetos de tipo String para armar el inventario del héroe.',
  learningContextParagraphs: const [
    'Una lista es una colección ordenada. Al declarar el tipo de sus elementos, el analizador puede detectar valores incompatibles.',
    'El inventario contiene varios elementos de texto y debe impedir que se agreguen objetos de otro tipo.',
  ],
  instructions: const [
    'Observa los elementos incluidos en el inventario.',
    'Identifica que forman una colección ordenada de texto.',
    'Elige la colección tipada que solo acepte esos elementos.',
  ],
  hint: 'La colección debe conservar el orden y aceptar únicamente texto.',
  category: MissionCategory.dartBasics,
  targetPlaceholder: '{{ listType }}',
  codeTemplate: [
    '{{ listType }} inventario = ["Espada", "Escudo", "Poción"];',
    'print("Items: \${inventario.length}");',
  ],
  options: const [
    MissionOption(
      id: 'List<String>',
      label: 'List<String>',
      codeSnippet: 'List<String>',
    ),
    MissionOption(
      id: 'Map<String>',
      label: 'Map<String>',
      codeSnippet: 'Map<String>',
    ),
    MissionOption(id: 'Set', label: 'Set', codeSnippet: 'Set'),
  ],
  correctOptionId: 'List<String>',
  previewBuilder: (context, selectedOptionId) {
    final bool isCorrect = selectedOptionId == 'List<String>';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield,
                color: isCorrect ? Colors.cyanAccent : Colors.grey,
                size: 40,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.colorize,
                color: isCorrect ? Colors.redAccent : Colors.grey,
                size: 40,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.security,
                color: isCorrect ? Colors.amberAccent : Colors.grey,
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isCorrect
                ? 'Inventario: 3 Objetos equipados'
                : 'Error de colección',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  },
);
