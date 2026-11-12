import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/repositories/catalog_repository.dart';
import 'core/store/session_store.dart';
import 'features/auth/view/session_gate.dart';
import 'features/home/view/student_theme.dart';

class FlutterQuestApp extends StatelessWidget {
  const FlutterQuestApp({super.key, required this.catalogRepository});

  final FlutterQuestRepository catalogRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SessionStore(catalogRepository)..initialize(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Quest',
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: QuestColors.background,
          colorScheme: const ColorScheme.dark(
            primary: QuestColors.training,
            secondary: QuestColors.boss,
            surface: QuestColors.surface,
            error: QuestColors.danger,
          ),
          cardTheme: CardThemeData(
            color: QuestColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: QuestColors.border),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: QuestColors.training,
              foregroundColor: QuestColors.background,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        home: SessionGate(repository: catalogRepository),
      ),
    );
  }
}
