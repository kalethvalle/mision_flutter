import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/repositories/catalog_repository.dart';
import 'core/store/game_store.dart';
import 'features/home/view/home_screen.dart';

class FlutterQuestApp extends StatelessWidget {
  const FlutterQuestApp({super.key, required this.catalogRepository});

  final FlutterQuestRepository catalogRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameStore(catalogRepository)..initialize(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Quest',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0F172A),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
