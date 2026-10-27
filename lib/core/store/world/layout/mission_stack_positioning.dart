import 'package:flutter/material.dart';

import '../../../models/mission_model.dart';

final missionStackPositioning = MissionModel(
  id: 'w2_m4',
  worldId: 'world_2',
  worldTitle: 'Mundo 2: Layouts & Flexbox',
  missionTitle: 'Misión 4 • Superposición con Stack',
  description: 'Superpone el escudo protector exactamente en la esquina superior derecha del personaje usando Positioned.',
  learningContextParagraphs: const [
    'Stack permite superponer widgets. Positioned ubica un hijo usando distancias desde los bordes del área apilada.',
    'El escudo debe superponerse al personaje tomando como referencia los bordes superior y derecho.',
  ],
  instructions: const [
    'Localiza la silueta objetivo alrededor del personaje.',
    'Identifica los dos bordes que forman esa esquina.',
    'Elige los desplazamientos asociados con ambos bordes.',
  ],
  hint: 'La referencia combina los bordes superior y derecho del Stack.',
  category: MissionCategory.layout,
  targetPlaceholder: '{{ positioning }}',
  codeTemplate: [
    'Stack(',
    '  children: [',
    '    HeroeWidget(),',
    '    Positioned(',
    '      {{ positioning }},',
    '      child: Escudo(),',
    '    ),',
    '  ],',
    ')',
  ],
  options: const [
    MissionOption(
      id: 'top_right',
      label: 'top: 10, right: 10',
      codeSnippet: 'top: 10, right: 10',
    ),
    MissionOption(
      id: 'bottom_left',
      label: 'bottom: 10, left: 10',
      codeSnippet: 'bottom: 10, left: 10',
    ),
    MissionOption(
      id: 'center',
      label: 'top: 100, left: 100',
      codeSnippet: 'top: 100, left: 100',
    ),
  ],
  correctOptionId: 'top_right',
  previewBuilder: (context, selectedOptionId) {
    double? top, right, bottom, left;
    if (selectedOptionId == 'top_right') {
      top = 10;
      right = 10;
    } else if (selectedOptionId == 'bottom_left') {
      bottom = 10;
      left = 10;
    } else if (selectedOptionId == 'center') {
      top = 70;
      left = 70;
    }

    return Center(
      child: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: const Icon(Icons.person, size: 80, color: Colors.white70),
            ),
            if (selectedOptionId.isNotEmpty)
              Positioned(
                top: top,
                right: right,
                bottom: bottom,
                left: left,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.black,
                    size: 28,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  },
);
