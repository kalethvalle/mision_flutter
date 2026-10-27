import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/store/game_store.dart';
import 'mission_view.dart';
import 'world_map_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GameStore>();

    switch (store.activeScreen) {
      case ActiveScreen.worldMap:
        return const WorldMapView();
      case ActiveScreen.mission:
        return const MissionView();
    }
  }
}