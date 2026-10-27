// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../../core/models/mission_model.dart';
// import '../../../core/store/game_store.dart';

// class MissionView extends StatelessWidget {
//   const MissionView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final store = context.watch<GameStore>();
//     final mission = store.currentMission;
//     final isDesktop = MediaQuery.of(context).size.width > 800;

//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF1E293B),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.map_rounded, color: Color(0xFF38BDF8)),
//           onPressed: store.goToWorldMap,
//           tooltip: 'Volver al Mapa',
//         ),
//         title: Text(
//           '${mission.worldTitle} (${store.currentMissionNumber}/${store.totalMissions})',
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back),
//             onPressed: store.hasPrevMission ? store.previousMission : null,
//           ),
//           IconButton(
//             icon: const Icon(Icons.arrow_forward),
//             onPressed: store.hasNextMission ? store.nextMission : null,
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: isDesktop
//             ? Row(
//                 children: [
//                   Expanded(flex: 5, child: _EditorPanel(mission: mission)),
//                   const VerticalDivider(width: 1, color: Color(0xFF334155)),
//                   Expanded(flex: 6, child: _PreviewPanel(mission: mission)),
//                 ],
//               )
//             : Column(
//                 children: [
//                   Expanded(flex: 5, child: _PreviewPanel(mission: mission)),
//                   Expanded(flex: 6, child: _EditorPanel(mission: mission)),
//                 ],
//               ),
//       ),
//     );
//   }
// }

// class _EditorPanel extends StatelessWidget {
//   final MissionModel mission;
//   const _EditorPanel({required this.mission});

//   @override
//   Widget build(BuildContext context) {
//     final store = context.watch<GameStore>();

//     return Container(
//       padding: const EdgeInsets.all(20),
//       color: const Color(0xFF1E293B),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(mission.missionTitle,
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
//           const SizedBox(height: 8),
//           Text(mission.description, style: const TextStyle(color: Color(0xFF94A3B8))),
//           const Divider(height: 24, color: Color(0xFF334155)),

//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF0F172A),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: const Color(0xFF334155)),
//               ),
//               child: ListView(
//                 children: mission.codeTemplate.map((line) {
//                   if (line.contains(mission.targetPlaceholder)) {
//                     final selectedOption = mission.options.firstWhere(
//                       (o) => o.id == store.selectedOptionId,
//                       orElse: () => const MissionOption(
//                           id: '', label: '[ SELECCIONA ]', codeSnippet: '[ SELECCIONA ]'),
//                     );
//                     return Text(
//                       line.replaceAll(mission.targetPlaceholder, selectedOption.codeSnippet),
//                       style: const TextStyle(
//                           fontFamily: 'monospace', color: Colors.amberAccent, fontWeight: FontWeight.bold),
//                     );
//                   }
//                   return Text(line, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFE2E8F0)));
//                 }).toList(),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),

//           Wrap(
//             spacing: 8,
//             children: mission.options.map((opt) {
//               final isSelected = store.selectedOptionId == opt.id;
//               return ChoiceChip(
//                 label: Text(opt.label),
//                 selected: isSelected,
//                 selectedColor: const Color(0xFF38BDF8),
//                 backgroundColor: const Color(0xFF334155),
//                 onSelected: (_) => store.selectOption(opt.id),
//               );
//             }).toList(),
//           ),
//           const SizedBox(height: 16),

//           SizedBox(
//             width: double.infinity,
//             height: 48,
//             child: ElevatedButton.icon(
//               style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
//               onPressed: store.selectedOptionId.isNotEmpty ? store.checkAnswer : null,
//               icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
//               label: const Text('PROBAR CÓDIGO', style: TextStyle(fontWeight: FontWeight.bold)),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _PreviewPanel extends StatelessWidget {
//   final MissionModel mission;
//   const _PreviewPanel({required this.mission});

//   @override
//   Widget build(BuildContext context) {
//     final store = context.watch<GameStore>();

//     return Container(
//       padding: const EdgeInsets.all(20),
//       color: const Color(0xFF0F172A),
//       child: Column(
//         children: [
//           if (store.isSuccess)
//             Container(
//               padding: const EdgeInsets.all(12),
//               margin: const EdgeInsets.only(bottom: 12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF10B981).withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: const Color(0xFF10B981)),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.check_circle, color: Color(0xFF10B981)),
//                   const SizedBox(width: 8),
//                   const Text('¡Excelente! Misión completada.', style: TextStyle(color: Colors.white)),
//                   const Spacer(),
//                   if (store.hasNextMission)
//                     ElevatedButton(
//                       onPressed: store.nextMission,
//                       child: const Text('SIGUIENTE'),
//                     )
//                   else
//                     ElevatedButton(
//                       onPressed: store.goToWorldMap,
//                       child: const Text('IR AL MAPA'),
//                     ),
//                 ],
//               ),
//             ),
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1E293B),
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: const Color(0xFF334155)),
//               ),
//               child: mission.previewBuilder(context, store.selectedOptionId),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/mission_model.dart';
import '../../../core/store/game_store.dart';

class MissionView extends StatelessWidget {
  const MissionView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();
    final mission = store.currentMission;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate 900
      appBar: _buildAppBar(context, store, mission),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  Expanded(flex: 5, child: _EditorPanel(mission: mission)),
                  const VerticalDivider(width: 1, color: Color(0xFF334155)),
                  Expanded(flex: 6, child: _PreviewPanel(mission: mission)),
                ],
              )
            : Column(
                children: [
                  Expanded(flex: 6, child: _EditorPanel(mission: mission)),
                  Expanded(flex: 5, child: _PreviewPanel(mission: mission)),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    GameStore store,
    MissionModel mission,
  ) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.map_rounded, color: Color(0xFF38BDF8)),
        onPressed: store.goToWorldMap,
        tooltip: 'Volver al Mapa',
      ),
      title: isCompact
          ? const Text(
              'Flutter Quest',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            )
          : Row(
              children: [
                const Icon(Icons.extension_rounded, color: Color(0xFF38BDF8)),
                const SizedBox(width: 8),
                const Text(
                  'Flutter Quest',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0284C7)),
                    ),
                    child: Text(
                      '${mission.worldTitle} • ${mission.missionTitle}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF38BDF8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: store.hasPrevMission ? store.previousMission : null,
          tooltip: 'Misión Anterior',
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: store.hasNextMission ? store.nextMission : null,
          tooltip: 'Siguiente Misión',
        ),
        IconButton(
          icon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(mission.hint),
                backgroundColor: const Color(0xFF0284C7),
              ),
            );
          },
          tooltip: 'Pista',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _EditorPanel extends StatelessWidget {
  final MissionModel mission;
  const _EditorPanel({required this.mission});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();

    return Container(
      color: const Color(0xFF1E293B), // Slate 800
      child: LayoutBuilder(
        builder: (context, constraints) {
          final codePanelHeight = constraints.maxWidth < 600 ? 180.0 : 240.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MissionGuidanceCard(mission: mission),
                const SizedBox(height: 20),
                SizedBox(
                  height: codePanelHeight,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: mission.codeTemplate.map((line) {
                          if (line.contains(mission.targetPlaceholder)) {
                            final selectedOption = mission.options.firstWhere(
                              (option) => option.id == store.selectedOptionId,
                              orElse: () => const MissionOption(
                                id: '',
                                label: '[ SELECCIONA ]',
                                codeSnippet: '[ SELECCIONA ]',
                              ),
                            );
                            final parts = line.split(mission.targetPlaceholder);

                            return Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _codeLine(parts[0]),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8)
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: store.selectedOptionId.isEmpty
                                          ? Colors.amber
                                          : const Color(0xFF38BDF8),
                                    ),
                                  ),
                                  child: Text(
                                    selectedOption.codeSnippet,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (parts.length > 1) _codeLine(parts[1]),
                              ],
                            );
                          }
                          return _codeLine(line);
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Opciones disponibles:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: mission.options.map((option) {
                    final isSelected = store.selectedOptionId == option.id;
                    return ChoiceChip(
                      label: Text(
                        option.label,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF38BDF8),
                      backgroundColor: const Color(0xFF334155),
                      onSelected: (selected) {
                        store.selectOption(selected ? option.id : '');
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: store.selectedOptionId.isNotEmpty
                        ? store.checkAnswer
                        : null,
                    icon: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'PROBAR CÓDIGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _codeLine(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'monospace',
        color: Color(0xFFE2E8F0),
        fontSize: 14,
        height: 1.5,
      ),
    );
  }
}

class _MissionGuidanceCard extends StatelessWidget {
  final MissionModel mission;

  const _MissionGuidanceCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('mission-guidance-${mission.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172554), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330EA5E9),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_rounded, color: Color(0xFF38BDF8)),
              SizedBox(width: 8),
              Text(
                'ANTES DE COMENZAR',
                style: TextStyle(
                  color: Color(0xFF7DD3FC),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mission.missionTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mission.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFCBD5E1),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          const _GuidanceSectionTitle(
            icon: Icons.menu_book_rounded,
            label: 'Lo que aprenderás',
          ),
          const SizedBox(height: 8),
          Text(
            mission.learningContextParagraphs[0],
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mission.learningContextParagraphs[1],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFBAE6FD),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const _GuidanceSectionTitle(
            icon: Icons.route_rounded,
            label: 'Pasos para resolver',
          ),
          const SizedBox(height: 8),
          ...List.generate(mission.instructions.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == mission.instructions.length - 1 ? 0 : 8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0EA5E9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mission.instructions[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _GuidanceSectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GuidanceSectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final MissionModel mission;
  const _PreviewPanel({required this.mission});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();

    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          // Banner de Éxito[cite: 1]
          if (store.isSuccess)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  const Text(
                    '¡Excelente! Misión completada.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (store.hasNextMission)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                      ),
                      onPressed: store.nextMission,
                      child: const Text(
                        'SIGUIENTE',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                      ),
                      onPressed: store.goToWorldMap,
                      child: const Text(
                        'IR AL MAPA',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Banner de Error
          if (store.showError)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'Las posiciones no coinciden. ¡Intenta con otra opción!',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

          // Canvas de Vista Previa[cite: 1]
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: store.isSuccess
                      ? const Color(0xFF10B981)
                      : const Color(0xFF334155),
                  width: 2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: KeyedSubtree(
                  key: ValueKey(store.selectedOptionId),
                  child: mission.previewBuilder(
                    context,
                    store.selectedOptionId,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
