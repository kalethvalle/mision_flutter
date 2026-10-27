import 'package:flutter/material.dart';

import '../../../models/mission_model.dart';

final missionArrowFunctions = MissionModel(
  id: 'w1_m3',
  worldId: 'world_1',
  worldTitle: 'Mundo 1: Fundamentos de Dart',
  missionTitle: 'Misión 3 • Funciones Flecha (=>)',
  description: 'Completa la función de ataque especial simplificando su retorno con la sintaxis de flecha (=>).',
  learningContextParagraphs: const [
    'Una función que retorna una sola expresión puede escribirse de forma abreviada. La expresión se evalúa y su resultado se devuelve automáticamente.',
    'El ataque especial solo necesita calcular y retornar el doble de la fuerza recibida.',
  ],
  instructions: const [
    'Observa que la función solo calcula fuerza multiplicada por dos.',
    'Relaciona ese cálculo con el retorno de una sola expresión.',
    'Compara los operadores y elige la sintaxis abreviada.',
  ],
  hint:
      'Busca la forma equivalente a un bloque que solo retorna una expresión.',
  category: MissionCategory.dartBasics,
  targetPlaceholder: '{{ arrow }}',
  codeTemplate: ['int calcularAtaque(int fuerza) {{ arrow }} fuerza * 2;'],
  options: const [
    MissionOption(id: 'arrow', label: '=>', codeSnippet: '=>'),
    MissionOption(id: 'colon', label: ':', codeSnippet: ':'),
    MissionOption(id: 'equal', label: '=', codeSnippet: '='),
  ],
  correctOptionId: 'arrow',
  previewBuilder: (context, selectedOptionId) {
    final bool isCorrect = selectedOptionId == 'arrow';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flash_on_rounded,
            color: isCorrect ? Colors.amberAccent : Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isCorrect ? 'Ataque Especial: 50 de Daño' : 'Sintaxis inválida',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isCorrect ? Colors.amberAccent : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  },
);
