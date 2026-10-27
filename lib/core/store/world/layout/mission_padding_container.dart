import 'package:flutter/material.dart';

import '../../../models/mission_model.dart';

final missionPaddingContainer = MissionModel(
  id: 'w2_m3',
  worldId: 'world_2',
  worldTitle: 'Mundo 2: Layouts & Flexbox',
  missionTitle: 'Misión 3 • Dimensiones y Padding',
  description: 'Aplica el espaciado interno correcto (Padding) para separar la gema del borde del contenedor.',
  learningContextParagraphs: const [
    'El padding es el espacio interno entre un contenedor y su hijo. Puede aplicarse uniformemente o configurarse de forma independiente por borde.',
    'La gema necesita la misma separación interna de 32 píxeles en sus cuatro lados.',
  ],
  instructions: const [
    'Observa la distancia entre la gema y cada borde.',
    'Descarta la ausencia de espacio y el ajuste de un solo lado.',
    'Elige una separación interna uniforme de 32 píxeles.',
  ],
  hint: 'La separación solicitada es interna, uniforme y de 32 píxeles.',
  category: MissionCategory.layout,
  targetPlaceholder: '{{ padding }}',
  codeTemplate: [
    'Container(',
    '  padding: {{ padding }},',
    '  color: Colors.indigo,',
    '  child: GemaWidget(),',
    ')',
  ],
  options: const [
    MissionOption(
      id: 'zero',
      label: 'EdgeInsets.zero',
      codeSnippet: 'EdgeInsets.zero',
    ),
    MissionOption(
      id: 'all_32',
      label: 'EdgeInsets.all(32.0)',
      codeSnippet: 'EdgeInsets.all(32.0)',
    ),
    MissionOption(
      id: 'only_top',
      label: 'EdgeInsets.only(top: 10)',
      codeSnippet: 'EdgeInsets.only(top: 10)',
    ),
  ],
  correctOptionId: 'all_32',
  previewBuilder: (context, selectedOptionId) {
    EdgeInsets padding = EdgeInsets.zero;
    if (selectedOptionId == 'all_32') {
      padding = const EdgeInsets.all(32.0);
    }
    if (selectedOptionId == 'only_top') {
      padding = const EdgeInsets.only(top: 10.0);
    }

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withOpacity(0.3),
          border: Border.all(color: const Color(0xFF3B82F6), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.star, color: Colors.black),
        ),
      ),
    );
  },
);
