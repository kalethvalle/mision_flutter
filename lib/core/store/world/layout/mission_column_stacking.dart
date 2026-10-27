import 'package:flutter/material.dart';
import '../../../models/mission_model.dart';

final missionColumnStacking = MissionModel(
  id: 'w2_m2',
  worldId: 'world_2',
  worldTitle: 'Mundo 2: Layouts & Flexbox',
  missionTitle: 'Misión 2 • Apilamiento Vertical (Column)',
  description:
      'Mueve la plataforma de salto hacia la parte inferior para que encaje en la silueta objetivo.',
  hint: 'Usa "end" para alinear elementos en el extremo inferior de una Column.',
  category: MissionCategory.layout,
  targetPlaceholder: '{{ v_alignment }}',
  codeTemplate: [
    'Column(',
    '  mainAxisAlignment: {{ v_alignment }},',
    '  children: [',
    '    PlataformaWidget(),',
    '  ],',
    ')',
  ],
  options: const [
    MissionOption(id: 'start', label: 'MainAxisAlignment.start', codeSnippet: 'MainAxisAlignment.start'),
    MissionOption(id: 'center', label: 'MainAxisAlignment.center', codeSnippet: 'MainAxisAlignment.center'),
    MissionOption(id: 'end', label: 'MainAxisAlignment.end', codeSnippet: 'MainAxisAlignment.end'),
  ],
  correctOptionId: 'end',
  previewBuilder: (context, selectedOptionId) {
    MainAxisAlignment alignment = MainAxisAlignment.start;
    if (selectedOptionId == 'center') alignment = MainAxisAlignment.center;
    if (selectedOptionId == 'end') alignment = MainAxisAlignment.end;

    return Stack(
      children: [
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 140,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Icon(Icons.star_border_rounded, color: Colors.amber)),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              mainAxisAlignment: alignment,
              children: [
                Container(
                  width: 140,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: Colors.lightBlueAccent.withOpacity(0.4), blurRadius: 10),
                    ],
                  ),
                  child: const Center(
                    child: Text('PLATAFORMA',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  },
);