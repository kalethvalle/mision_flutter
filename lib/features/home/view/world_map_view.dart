import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            Text('Flutter Quest • Selecciona un Mundo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
                    return Card(
                      color: world.isUnlocked ? const Color(0xFF1E293B) : const Color(0xFF111827),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: world.isUnlocked ? world.color : const Color(0xFF334155),
                          width: world.isUnlocked ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: world.isUnlocked ? world.color.withOpacity(0.2) : Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            world.isUnlocked ? world.icon : Icons.lock_rounded,
                            color: world.isUnlocked ? world.color : Colors.grey,
                            size: 32,
                          ),
                        ),
                        title: Text(
                          world.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: world.isUnlocked ? Colors.white : Colors.grey,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            world.description,
                            style: TextStyle(
                              color: world.isUnlocked ? const Color(0xFF94A3B8) : Colors.grey[600],
                            ),
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: world.isUnlocked ? world.color : Colors.grey[800],
                          ),
                          onPressed: world.isUnlocked ? () => store.selectWorld(world.id) : null,
                          child: Text(
                            world.isUnlocked ? 'ENTRAR' : 'BLOQUEADO',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
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