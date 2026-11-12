import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/assessment_model.dart';
import '../../../core/models/progress_model.dart';
import '../../../core/models/world_model.dart';
import '../../../core/store/assessment_store.dart';
import '../../../core/store/game_store.dart';
import '../../../core/store/session_store.dart';
import '../presentation/catalog_presentation_registry.dart';
import 'assessment_view.dart';
import 'student_theme.dart';

enum _StudentRoom { training, boss }

class WorldMapView extends StatefulWidget {
  const WorldMapView({super.key});

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> {
  _StudentRoom _room = _StudentRoom.training;

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
      backgroundColor: QuestColors.background,
      appBar: AppBar(
        backgroundColor: QuestColors.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.terminal_rounded, color: QuestColors.training),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Flutter Quest',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
              ),
            ),
            if (MediaQuery.sizeOf(context).width >= 760)
              _ProgressPill(store: store),
          ],
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width >= 600)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  session.user!.displayName,
                  style: const TextStyle(color: QuestColors.muted),
                ),
              ),
            ),
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
        message: 'Cargando catálogo local...',
        loading: true,
      ),
      LoadState.failure => _CenteredStatus(
        icon: Icons.cloud_off_rounded,
        message: store.worldsError ?? 'No fue posible cargar el catálogo.',
        actionLabel: 'Reintentar',
        onAction: store.retryWorlds,
      ),
      LoadState.empty => const _CenteredStatus(
        icon: Icons.public_off_rounded,
        message: 'No hay mundos publicados todavía.',
      ),
      LoadState.ready => _StudentHub(
        room: _room,
        onRoomChanged: (room) => setState(() => _room = room),
        store: store,
        assessments: assessments,
      ),
    };
  }
}

class _StudentHub extends StatelessWidget {
  const _StudentHub({
    required this.room,
    required this.onRoomChanged,
    required this.store,
    required this.assessments,
  });

  final _StudentRoom room;
  final ValueChanged<_StudentRoom> onRoomChanged;
  final GameStore store;
  final AssessmentStore assessments;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 16 : 24,
            compact ? 16 : 22,
            compact ? 16 : 24,
            12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room == _StudentRoom.training
                    ? 'Arena de entrenamiento'
                    : 'Cámara del jefe final',
                style: const TextStyle(
                  color: QuestColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                room == _StudentRoom.training
                    ? 'Practica cada mundo en orden y abre el siguiente portal con código correcto.'
                    : 'Presenta el parcial de cada mundo cuando hayas cerrado su ruta de misiones.',
                style: const TextStyle(color: QuestColors.muted, height: 1.35),
              ),
              const SizedBox(height: 18),
              _RoomSwitch(room: room, onChanged: onRoomChanged),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: room == _StudentRoom.training
                ? _TrainingArena(key: const ValueKey('arena'), store: store)
                : _BossChamber(
                    key: const ValueKey('boss'),
                    assessments: assessments,
                  ),
          ),
        ),
      ],
    );
  }
}

class _RoomSwitch extends StatelessWidget {
  const _RoomSwitch({required this.room, required this.onChanged});

  final _StudentRoom room;
  final ValueChanged<_StudentRoom> onChanged;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 520) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RoomButton(
              selected: room == _StudentRoom.training,
              icon: Icons.fitness_center_rounded,
              label: 'Arena de entrenamiento',
              onPressed: () => onChanged(_StudentRoom.training),
            ),
            const SizedBox(height: 8),
            _RoomButton(
              selected: room == _StudentRoom.boss,
              icon: Icons.local_fire_department_rounded,
              label: 'Jefe final',
              onPressed: () => onChanged(_StudentRoom.boss),
            ),
          ],
        );
      }
      return SegmentedButton<_StudentRoom>(
        segments: const [
          ButtonSegment(
            value: _StudentRoom.training,
            icon: Icon(Icons.fitness_center_rounded),
            label: Text('Arena de entrenamiento'),
          ),
          ButtonSegment(
            value: _StudentRoom.boss,
            icon: Icon(Icons.local_fire_department_rounded),
            label: Text('Jefe final'),
          ),
        ],
        selected: {room},
        onSelectionChanged: (selection) => onChanged(selection.single),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? QuestColors.training.withValues(alpha: 0.18)
                : QuestColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? QuestColors.text
                : QuestColors.muted,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? QuestColors.training
                  : QuestColors.border,
            ),
          ),
        ),
      );
    },
  );
}

class _RoomButton extends StatelessWidget {
  const _RoomButton({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
    return selected
        ? FilledButton(onPressed: onPressed, child: child)
        : OutlinedButton(onPressed: onPressed, child: child);
  }
}

class _TrainingArena extends StatelessWidget {
  const _TrainingArena({super.key, required this.store});

  final GameStore store;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      itemCount: store.worlds.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final world = store.worlds[index];
        return _TrainingWorldCard(
          world: world,
          progress: store.worldProgress(world.id),
          onEnter: world.isUnlocked ? () => store.selectWorld(world.id) : null,
        );
      },
    );
  }
}

class _TrainingWorldCard extends StatelessWidget {
  const _TrainingWorldCard({
    required this.world,
    required this.progress,
    required this.onEnter,
  });

  final WorldModel world;
  final WorldProgressState? progress;
  final VoidCallback? onEnter;

  @override
  Widget build(BuildContext context) {
    final worldColor = CatalogPresentationRegistry.worldColor(world.colorHex);
    final locked = !world.isUnlocked;
    final completed = progress?.completedMissions ?? 0;
    final total = progress?.totalMissions ?? 0;
    final ratio = total == 0 ? 0.0 : completed / total;
    return QuestCard(
      borderColor: locked ? QuestColors.border : worldColor,
      backgroundColor: locked ? const Color(0xFF111827) : QuestColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 660;
          final header = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorldMark(world: world, locked: locked, color: worldColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      world.title,
                      style: TextStyle(
                        color: locked ? QuestColors.muted : QuestColors.text,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      world.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: QuestColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final action = FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: locked ? QuestColors.border : worldColor,
              foregroundColor: locked
                  ? QuestColors.muted
                  : QuestColors.background,
              minimumSize: Size(compact ? double.infinity : 136, 48),
            ),
            onPressed: onEnter,
            icon: Icon(locked ? Icons.lock_rounded : Icons.play_arrow_rounded),
            label: Text(locked ? 'Bloqueado' : 'Entrar'),
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  color: locked ? QuestColors.muted : worldColor,
                  backgroundColor: QuestColors.background,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.route_rounded,
                    text: '$completed/$total misiones',
                    color: worldColor,
                  ),
                  ...world.topics.map(
                    (topic) => _InfoChip(
                      icon: Icons.code_rounded,
                      text: topic.title,
                      color: locked ? QuestColors.muted : worldColor,
                    ),
                  ),
                ],
              ),
              if (locked && progress?.lockReason != null) ...[
                const SizedBox(height: 12),
                Text(
                  progress!.lockReason!,
                  style: const TextStyle(color: QuestColors.boss),
                ),
              ],
            ],
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [content, const SizedBox(height: 18), action],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 24),
                    action,
                  ],
                );
        },
      ),
    );
  }
}

class _BossChamber extends StatelessWidget {
  const _BossChamber({super.key, required this.assessments});

  final AssessmentStore assessments;

  @override
  Widget build(BuildContext context) {
    if (assessments.state == AssessmentLoadState.loading) {
      return const _CenteredStatus(
        icon: Icons.hourglass_top_rounded,
        message: 'Consultando jefes finales...',
        loading: true,
      );
    }
    if (assessments.state == AssessmentLoadState.failure) {
      return _CenteredStatus(
        icon: Icons.warning_amber_rounded,
        message: assessments.error ?? 'No fue posible cargar los parciales.',
        actionLabel: 'Reintentar',
        onAction: assessments.load,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      children: [
        ...assessments.overview.availability.map(
          (availability) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _BossWorldCard(
              availability: availability,
              onOpen: () =>
                  _openAssessment(context, assessments, availability.worldId),
            ),
          ),
        ),
        _HistoryPanel(assessments: assessments),
      ],
    );
  }
}

class _BossWorldCard extends StatelessWidget {
  const _BossWorldCard({required this.availability, required this.onOpen});

  final AssessmentAvailability availability;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final available = availability.isAvailable;
    final accent = available ? QuestColors.boss : QuestColors.border;
    return QuestCard(
      borderColor: accent,
      backgroundColor: available
          ? QuestColors.surfaceRaised
          : const Color(0xFF111827),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final status = available
              ? '${availability.publishedQuestions} preguntas listas'
              : availability.reason ?? 'No disponible';
          final action = FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: available
                  ? QuestColors.boss
                  : QuestColors.border,
              foregroundColor: QuestColors.background,
              minimumSize: Size(compact ? double.infinity : 156, 48),
            ),
            onPressed: available ? onOpen : null,
            icon: Icon(
              availability.openAttemptId != null
                  ? Icons.restart_alt_rounded
                  : Icons.local_fire_department_rounded,
            ),
            label: Text(
              availability.openAttemptId != null
                  ? 'Continuar jefe'
                  : 'Jefe final',
            ),
          );
          final detail = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    available
                        ? Icons.local_fire_department_rounded
                        : Icons.lock_clock_rounded,
                    color: accent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      availability.worldTitle,
                      style: const TextStyle(
                        color: QuestColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(status, style: const TextStyle(color: QuestColors.muted)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.checklist_rounded,
                    text:
                        '${availability.completedMissions}/${availability.totalMissions} misiones',
                    color: available ? QuestColors.boss : QuestColors.muted,
                  ),
                  _InfoChip(
                    icon: Icons.history_rounded,
                    text: '${availability.completedAttempts} intentos',
                    color: QuestColors.muted,
                  ),
                  if (availability.bestScore != null)
                    _InfoChip(
                      icon: Icons.emoji_events_rounded,
                      text: 'Mejor nota ${availability.bestScore}/100',
                      color: QuestColors.success,
                    ),
                ],
              ),
            ],
          );
          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [detail, const SizedBox(height: 18), action],
                )
              : Row(
                  children: [
                    Expanded(child: detail),
                    const SizedBox(width: 24),
                    action,
                  ],
                );
        },
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.assessments});

  final AssessmentStore assessments;

  @override
  Widget build(BuildContext context) {
    final history = assessments.overview.history;
    return QuestCard(
      borderColor: QuestColors.boss.withValues(alpha: 0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: QuestColors.boss),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Historial de parciales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            const Text(
              'Aún no has entregado parciales.',
              style: TextStyle(color: QuestColors.muted),
            )
          else
            ...history.map(
              (item) => Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: item.passed
                        ? QuestColors.success
                        : QuestColors.boss,
                    foregroundColor: QuestColors.background,
                    child: Text('${item.score}'),
                  ),
                  title: Text(item.worldTitle),
                  subtitle: Text(
                    '${item.correctAnswers}/${item.totalQuestions} correctas',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final loaded = await assessments.showResult(item.id);
                    if (loaded && context.mounted) {
                      await Navigator.push<void>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssessmentView(store: assessments),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorldMark extends StatelessWidget {
  const _WorldMark({
    required this.world,
    required this.locked,
    required this.color,
  });

  final WorldModel world;
  final bool locked;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(
      color: locked ? QuestColors.background : color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: locked ? QuestColors.border : color),
    ),
    child: Icon(
      locked
          ? Icons.lock_rounded
          : CatalogPresentationRegistry.worldIcon(world.iconKey),
      color: locked ? QuestColors.muted : color,
      size: 30,
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: QuestColors.background,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: 0.45)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 210),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: QuestColors.text, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.store});

  final GameStore store;

  @override
  Widget build(BuildContext context) {
    final completed = store.worlds.fold<int>(
      0,
      (sum, world) =>
          sum + (store.worldProgress(world.id)?.completedMissions ?? 0),
    );
    final total = store.worlds.fold<int>(
      0,
      (sum, world) => sum + (store.worldProgress(world.id)?.totalMissions ?? 0),
    );
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: QuestColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: QuestColors.border),
      ),
      child: Text(
        'Progreso $completed/$total',
        style: const TextStyle(color: QuestColors.muted, fontSize: 13),
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
              Icon(icon, size: 54, color: QuestColors.muted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: QuestColors.text),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
