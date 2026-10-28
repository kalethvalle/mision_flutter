import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/world_model.dart';
import '../../../core/store/game_store.dart';
import '../presentation/catalog_presentation_registry.dart';

class WorldMapView extends StatelessWidget {
  const WorldMapView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();
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
      ),
      body: SafeArea(child: _bodyFor(store)),
    );
  }

  Widget _bodyFor(GameStore store) {
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
      LoadState.ready => _WorldList(store: store),
    };
  }
}

class _WorldList extends StatelessWidget {
  const _WorldList({required this.store});

  final GameStore store;

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
                  onEnter: world.isUnlocked
                      ? () => store.selectWorld(world.id)
                      : null,
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
  const _WorldLearningCard({required this.world, required this.onEnter});

  final WorldModel world;
  final VoidCallback? onEnter;

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
                      SizedBox(width: double.infinity, child: button),
                    ],
                  )
                : Row(
                    children: [
                      icon,
                      const SizedBox(width: 18),
                      Expanded(child: details),
                      const SizedBox(width: 24),
                      button,
                    ],
                  ),
          );
        },
      ),
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
