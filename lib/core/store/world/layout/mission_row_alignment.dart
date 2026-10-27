import 'package:flutter/material.dart';
import '../../../models/mission_model.dart';

final missionRowAlignment = MissionModel(
  id: 'w2_m1',
  worldId: 'world_2',
  worldTitle: 'Mundo 2: Layouts & Flexbox',
  missionTitle: 'Misión 1 • Distribución Horizontal (Row)',
  description:
      'Ajusta la alineación del Row para colocar las 3 gemas dentro de los objetivos marcados.',
  hint: 'Usa "spaceBetween" para colocar elementos al inicio, al final y con espacio uniforme.',
  category: MissionCategory.layout,
  targetPlaceholder: '{{ alignment }}',
  codeTemplate: [
    'Row(',
    '  mainAxisAlignment: {{ alignment }},',
    '  children: [',
    '    GemaWidget(color: Colors.purple),',
    '    GemaWidget(color: Colors.cyan),',
    '    GemaWidget(color: Colors.green),',
    '  ],',
    ')',
  ],
  options: const [
    MissionOption(id: 'center', label: 'MainAxisAlignment.center', codeSnippet: 'MainAxisAlignment.center'),
    MissionOption(id: 'space_between', label: 'MainAxisAlignment.spaceBetween', codeSnippet: 'MainAxisAlignment.spaceBetween'),
    MissionOption(id: 'end', label: 'MainAxisAlignment.end', codeSnippet: 'MainAxisAlignment.end'),
  ],
  correctOptionId: 'space_between',
  previewBuilder: (context, selectedOptionId) {
    MainAxisAlignment alignment = MainAxisAlignment.start;
    if (selectedOptionId == 'center') alignment = MainAxisAlignment.center;
    if (selectedOptionId == 'space_between') alignment = MainAxisAlignment.spaceBetween;
    if (selectedOptionId == 'end') alignment = MainAxisAlignment.end;

    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (index) => Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withOpacity(0.4), width: 2),
                  ),
                  child: const Center(child: Icon(Icons.star_border_rounded, color: Colors.amber)),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: alignment,
              children: const [
                _Gema(color: Colors.purpleAccent),
                _Gema(color: Colors.cyanAccent),
                _Gema(color: Colors.greenAccent),
              ],
            ),
          ),
        ),
      ],
    );
  },
);

class _Gema extends StatelessWidget {
  final Color color;
  const _Gema({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)],
      ),
      child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 32),
    );
  }
}