import 'package:flutter/material.dart';

enum MissionCategory { dartBasics, layout, interactivity }

class MissionOption {
  final String id;
  final String label;
  final String codeSnippet;

  const MissionOption({
    required this.id,
    required this.label,
    required this.codeSnippet,
  });
}

class MissionModel {
  final String id;
  final String worldId; // <-- Asociación de mundo
  final String worldTitle;
  final String missionTitle;
  final String description;
  final List<String> learningContextParagraphs;
  final List<String> instructions;
  final String hint;
  final MissionCategory category;
  final List<String> codeTemplate;
  final String targetPlaceholder;
  final List<MissionOption> options;
  final String correctOptionId;
  final Widget Function(BuildContext context, String selectedOptionId)
  previewBuilder;

  const MissionModel({
    required this.id,
    required this.worldId,
    required this.worldTitle,
    required this.missionTitle,
    required this.description,
    required this.learningContextParagraphs,
    required this.instructions,
    required this.hint,
    required this.category,
    required this.codeTemplate,
    required this.targetPlaceholder,
    required this.options,
    required this.correctOptionId,
    required this.previewBuilder,
  });
}
