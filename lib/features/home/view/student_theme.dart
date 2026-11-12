import 'package:flutter/material.dart';

class QuestColors {
  const QuestColors._();

  static const background = Color(0xFF0B1020);
  static const surface = Color(0xFF16213E);
  static const surfaceRaised = Color(0xFF1D2B4F);
  static const border = Color(0xFF31415F);
  static const text = Color(0xFFE2E8F0);
  static const muted = Color(0xFF96A3B8);
  static const training = Color(0xFF2DD4BF);
  static const boss = Color(0xFFF59E0B);
  static const flutter = Color(0xFF8B5CF6);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFFB7185);
}

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderColor = QuestColors.border,
    this.backgroundColor = QuestColors.surface,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor),
    ),
    child: child,
  );
}
