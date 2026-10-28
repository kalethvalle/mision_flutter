import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/mission_model.dart';
import '../../../core/store/game_store.dart';
import '../presentation/catalog_presentation_registry.dart';

class MissionView extends StatelessWidget {
  const MissionView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();
    final mission = store.currentMissionOrNull;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(context, store, mission),
      body: SafeArea(child: _bodyFor(context, store, mission)),
    );
  }

  Widget _bodyFor(
    BuildContext context,
    GameStore store,
    MissionModel? mission,
  ) {
    if (store.missionsState == LoadState.loading ||
        store.missionsState == LoadState.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (store.missionsState == LoadState.failure) {
      return _MissionStatus(
        icon: Icons.cloud_off_rounded,
        message: store.missionsError ?? 'No fue posible cargar las misiones.',
        action: store.retryCurrentWorld,
      );
    }
    if (store.missionsState == LoadState.empty || mission == null) {
      return const _MissionStatus(
        icon: Icons.extension_off_rounded,
        message: 'Este mundo no tiene misiones publicadas.',
      );
    }

    final desktop = MediaQuery.sizeOf(context).width > 800;
    return desktop
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
          );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    GameStore store,
    MissionModel? mission,
  ) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.map_rounded, color: Color(0xFF38BDF8)),
        onPressed: store.goToWorldMap,
        tooltip: 'Volver al Mapa',
      ),
      title: compact || mission == null
          ? const Text(
              'Flutter Quest',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            )
          : Text(
              '${mission.worldTitle} • ${mission.missionTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: Color(0xFF7DD3FC)),
            ),
      actions: mission == null
          ? const []
          : [
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
            ],
    );
  }
}

class _EditorPanel extends StatelessWidget {
  const _EditorPanel({required this.mission});

  final MissionModel mission;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();
    return Container(
      color: const Color(0xFF1E293B),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final codeHeight = constraints.maxWidth < 600 ? 180.0 : 240.0;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MissionGuidanceCard(mission: mission),
                const SizedBox(height: 20),
                SizedBox(
                  height: codeHeight,
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
                        children: mission.codeTemplate
                            .map((line) => _codeTemplateLine(line, store))
                            .toList(),
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
                    final selected = store.selectedOptionId == option.id;
                    return ChoiceChip(
                      label: Text(
                        option.label,
                        style: TextStyle(
                          color: selected ? Colors.black : Colors.white,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF38BDF8),
                      backgroundColor: const Color(0xFF334155),
                      onSelected: store.isCheckingAnswer
                          ? null
                          : (value) =>
                                store.selectOption(value ? option.id : ''),
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
                    onPressed:
                        store.selectedOptionId.isEmpty || store.isCheckingAnswer
                        ? null
                        : store.checkAnswer,
                    icon: store.isCheckingAnswer
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                          ),
                    label: Text(
                      store.isCheckingAnswer ? 'COMPROBANDO…' : 'PROBAR CÓDIGO',
                      style: const TextStyle(
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

  Widget _codeTemplateLine(String line, GameStore store) {
    if (!line.contains(mission.targetPlaceholder)) return _codeLine(line);
    final option = mission.options
        .where((item) => item.id == store.selectedOptionId)
        .firstOrNull;
    final parts = line.split(mission.targetPlaceholder);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _codeLine(parts.first),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: option == null ? Colors.amber : const Color(0xFF38BDF8),
            ),
          ),
          child: Text(
            option?.codeSnippet ?? '[ SELECCIONA ]',
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

  Widget _codeLine(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'monospace',
      color: Color(0xFFE2E8F0),
      fontSize: 14,
      height: 1.5,
    ),
  );
}

class _MissionGuidanceCard extends StatelessWidget {
  const _MissionGuidanceCard({required this.mission});

  final MissionModel mission;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('mission-guidance-${mission.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF172554), Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GuidanceTitle(
            icon: Icons.school_rounded,
            text: 'ANTES DE COMENZAR',
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
            style: const TextStyle(color: Color(0xFFCBD5E1), height: 1.35),
          ),
          const SizedBox(height: 18),
          const _GuidanceTitle(
            icon: Icons.menu_book_rounded,
            text: 'Lo que aprenderás',
          ),
          const SizedBox(height: 8),
          Text(
            mission.learningContextParagraphs[0],
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFE2E8F0), height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            mission.learningContextParagraphs[1],
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFBAE6FD),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          const _GuidanceTitle(
            icon: Icons.route_rounded,
            text: 'Pasos para resolver',
          ),
          const SizedBox(height: 8),
          ...mission.instructions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: const Color(0xFF0EA5E9),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
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

class _GuidanceTitle extends StatelessWidget {
  const _GuidanceTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
      const SizedBox(width: 8),
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.mission});

  final MissionModel mission;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();
    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          if (store.isSuccess)
            _FeedbackBanner(
              color: const Color(0xFF10B981),
              icon: Icons.check_circle,
              message: '¡Excelente! Misión completada.',
              action: store.hasNextMission
                  ? store.nextMission
                  : store.goToWorldMap,
              actionLabel: store.hasNextMission ? 'SIGUIENTE' : 'IR AL MAPA',
            ),
          if (store.showError)
            _FeedbackBanner(
              color: Colors.redAccent,
              icon: Icons.error_outline,
              message:
                  store.missionsError ??
                  'La respuesta no es correcta. ¡Intenta con otra opción!',
            ),
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
                  child: CatalogPresentationRegistry.missionPreview(
                    mission.previewType,
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

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.color,
    required this.icon,
    required this.message,
    this.action,
    this.actionLabel,
  });

  final Color color;
  final IconData icon;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.white)),
        ),
        if (action != null && actionLabel != null)
          TextButton(onPressed: action, child: Text(actionLabel!)),
      ],
    ),
  );
}

class _MissionStatus extends StatelessWidget {
  const _MissionStatus({
    required this.icon,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String message;
  final Future<void> Function()? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: action, child: const Text('REINTENTAR')),
          ],
        ],
      ),
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
