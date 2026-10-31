import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/world_model.dart';
import '../../../core/models/progress_model.dart';
import '../../../core/models/assessment_model.dart';
import '../../../core/store/assessment_store.dart';
import '../../../core/store/game_store.dart';
import '../../../core/store/session_store.dart';
import '../presentation/catalog_presentation_registry.dart';
import 'assessment_view.dart';

class WorldMapView extends StatefulWidget {
  const WorldMapView({super.key});

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => mounted ? context.read<AssessmentStore>().load() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();
    final session = context.watch<SessionStore>();
    final assessments = context.watch<AssessmentStore>();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.explore_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Flutter Quest • Selecciona un Mundo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showHistory(context, assessments),
            tooltip: 'Historial de parciales',
            icon: const Icon(Icons.history),
          ),
          if (MediaQuery.sizeOf(context).width >= 600)
            Center(child: Text(session.user!.displayName)),
          IconButton(
            onPressed: session.isSubmitting ? null : session.logout,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(child: _bodyFor(store, assessments)),
    );
  }

  Widget _bodyFor(GameStore store, AssessmentStore assessments) {
    return switch (store.worldsState) {
      LoadState.initial || LoadState.loading => const _CenteredStatus(
        icon: Icons.sync_rounded,
        message: 'Cargando catálogo local…',
        loading: true,
      ),
      LoadState.failure => _CenteredStatus(
        icon: Icons.cloud_off_rounded,
        message: store.worldsError ?? 'No fue posible cargar el catálogo.',
        actionLabel: 'REINTENTAR',
        onAction: store.retryWorlds,
      ),
      LoadState.empty => const _CenteredStatus(
        icon: Icons.public_off_rounded,
        message: 'No hay mundos publicados todavía.',
      ),
      LoadState.ready => _WorldList(store: store, assessments: assessments),
    };
  }

  Future<void> _showHistory(BuildContext context, AssessmentStore store) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Historial de parciales'),
        content: SizedBox(
          width: 560,
          child: store.overview.history.isEmpty
              ? const Text('Aún no has entregado parciales.')
              : ListView(
                  shrinkWrap: true,
                  children: store.overview.history
                      .map(
                        (item) => ListTile(
                          title: Text(item.worldTitle),
                          subtitle: Text(
                            '${item.score}/100 • ${item.passed ? 'APROBADO' : 'NO APROBADO'}',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            Navigator.pop(dialogContext);
                            final loaded = await store.showResult(item.id);
                            if (loaded && context.mounted) {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssessmentView(store: store),
                                ),
                              );
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CERRAR'),
          ),
        ],
      ),
    );
  }
}

class _WorldList extends StatelessWidget {
  const _WorldList({required this.store, required this.assessments});

  final GameStore store;
  final AssessmentStore assessments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mapa de Mundos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completa las misiones en orden para desbloquear los siguientes mundos.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: store.worlds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final world = store.worlds[index];
                return _WorldLearningCard(
                  world: world,
                  progress: store.worldProgress(world.id),
                  assessment: assessments.availabilityFor(world.id),
                  onEnter: world.isUnlocked
                      ? () => store.selectWorld(world.id)
                      : null,
                  onAssessment: () =>
                      _openAssessment(context, assessments, world.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldLearningCard extends StatelessWidget {
  const _WorldLearningCard({
    required this.world,
    required this.progress,
    required this.assessment,
    required this.onEnter,
    required this.onAssessment,
  });

  final WorldModel world;
  final WorldProgressState? progress;
  final AssessmentAvailability? assessment;
  final VoidCallback? onEnter;
  final VoidCallback onAssessment;

  @override
  Widget build(BuildContext context) {
    final color = CatalogPresentationRegistry.worldColor(world.colorHex);
    final foreground = world.isUnlocked ? Colors.white : Colors.grey;
    final detail = world.isUnlocked
        ? const Color(0xFFCBD5E1)
        : Colors.grey.shade600;

    return Card(
      color: world.isUnlocked
          ? const Color(0xFF1E293B)
          : const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: world.isUnlocked ? color : const Color(0xFF334155),
          width: world.isUnlocked ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final icon = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: world.isUnlocked
                  ? color.withValues(alpha: 0.2)
                  : Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(
              world.isUnlocked
                  ? CatalogPresentationRegistry.worldIcon(world.iconKey)
                  : Icons.lock_rounded,
              color: world.isUnlocked ? color : Colors.grey,
              size: 32,
            ),
          );
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                world.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, size: 17, color: color),
                  const SizedBox(width: 7),
                  Text(
                    'QUÉ APRENDERÁS',
                    style: TextStyle(
                      color: world.isUnlocked ? color : Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                world.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: detail, height: 1.35),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: world.topics.map((topic) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      topic.title,
                      style: TextStyle(fontSize: 11, color: detail),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                '${progress?.completedMissions ?? 0}/${progress?.totalMissions ?? 0} misiones completadas',
                style: TextStyle(
                  color: world.isUnlocked ? color : Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (!world.isUnlocked && progress?.lockReason != null) ...[
                const SizedBox(height: 5),
                Text(
                  progress!.lockReason!,
                  style: const TextStyle(color: Colors.amber, fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                assessment?.isAvailable == true
                    ? 'JEFE FINAL DISPONIBLE • ${assessment!.publishedQuestions} preguntas'
                    : assessment?.reason ?? 'Consultando jefe final…',
                style: TextStyle(
                  color: assessment?.isAvailable == true
                      ? Colors.amber
                      : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (assessment?.bestScore != null)
                Text(
                  'Mejor nota: ${assessment!.bestScore}/100',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 12,
                  ),
                ),
            ],
          );
          final button = ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(compact ? double.infinity : 120, 46),
              backgroundColor: world.isUnlocked ? color : Colors.grey.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onEnter,
            child: Text(
              world.isUnlocked ? 'ENTRAR' : 'BLOQUEADO',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
          final assessmentButton = OutlinedButton.icon(
            onPressed: assessment?.isAvailable == true ? onAssessment : null,
            icon: const Icon(Icons.sports_martial_arts),
            label: Text(
              assessment?.openAttemptId != null
                  ? 'CONTINUAR JEFE'
                  : 'JEFE FINAL',
            ),
          );
          final buttons = compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    button,
                    const SizedBox(height: 8),
                    assessmentButton,
                  ],
                )
              : Column(
                  children: [
                    button,
                    const SizedBox(height: 8),
                    assessmentButton,
                  ],
                );
          return Padding(
            padding: const EdgeInsets.all(20),
            child: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: 14),
                          Expanded(child: details),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(width: double.infinity, child: buttons),
                    ],
                  )
                : Row(
                    children: [
                      icon,
                      const SizedBox(width: 18),
                      Expanded(child: details),
                      const SizedBox(width: 24),
                      buttons,
                    ],
                  ),
          );
        },
      ),
    );
  }
}

Future<void> _openAssessment(
  BuildContext context,
  AssessmentStore store,
  String worldId,
) async {
  final availability = store.availabilityFor(worldId);
  final opened = availability?.openAttemptId == null
      ? await store.start(worldId)
      : await store.resume(availability!.openAttemptId!);
  if (opened && context.mounted) {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => AssessmentView(store: store)),
    );
  }
}

class _CenteredStatus extends StatelessWidget {
  const _CenteredStatus({
    required this.icon,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final bool loading;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 54, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFCBD5E1)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
