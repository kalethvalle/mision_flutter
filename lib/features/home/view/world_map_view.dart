import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/world_model.dart';
import '../../../core/store/game_store.dart';

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
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
        ),
      ),
    );
  }
}

class _WorldLearningCard extends StatelessWidget {
  final WorldModel world;
  final VoidCallback? onEnter;

  const _WorldLearningCard({required this.world, required this.onEnter});

  @override
  Widget build(BuildContext context) {
    final foregroundColor = world.isUnlocked ? Colors.white : Colors.grey;
    final detailColor = world.isUnlocked
        ? const Color(0xFFCBD5E1)
        : Colors.grey.shade600;

    return Card(
      color: world.isUnlocked
          ? const Color(0xFF1E293B)
          : const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: world.isUnlocked ? world.color : const Color(0xFF334155),
          width: world.isUnlocked ? 2 : 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final icon = Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: world.isUnlocked
                  ? world.color.withOpacity(0.2)
                  : Colors.black26,
              shape: BoxShape.circle,
            ),
            child: Icon(
              world.isUnlocked ? world.icon : Icons.lock_rounded,
              color: world.isUnlocked ? world.color : Colors.grey,
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
                  color: foregroundColor,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 17,
                    color: world.isUnlocked
                        ? world.color
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'QUÉ APRENDERÁS',
                    style: TextStyle(
                      color: world.isUnlocked
                          ? world.color
                          : Colors.grey.shade600,
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
                style: TextStyle(color: detailColor, height: 1.35),
              ),
            ],
          );
          final button = ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(isCompact ? double.infinity : 120, 46),
              backgroundColor: world.isUnlocked
                  ? world.color
                  : Colors.grey.shade800,
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
            child: isCompact
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
