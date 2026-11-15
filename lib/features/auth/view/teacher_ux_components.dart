import 'package:flutter/material.dart';

const teacherSurface = Color(0xFF172033);
const teacherSurfaceAlt = Color(0xFF1E293B);
const teacherTextMuted = Color(0xFFCBD5E1);
const teacherTextSoft = Color(0xFF94A3B8);
const teacherAccent = Color(0xFF38BDF8);
const teacherSuccess = Color(0xFF22C55E);
const teacherWarning = Color(0xFFF59E0B);

class TeacherPageHeader extends StatelessWidget {
  const TeacherPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
    this.footer,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: teacherSurface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white10),
    ),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 14,
          spacing: 20,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: teacherAccent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: teacherAccent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(color: teacherTextMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
        if (footer != null) ...[const SizedBox(height: 16), footer!],
      ],
    ),
  );
}

class TeacherMetricStrip extends StatelessWidget {
  const TeacherMetricStrip({super.key, required this.items});

  final List<TeacherMetricItem> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final itemWidth = available < 520 ? available : 170.0;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (item) => SizedBox(
                width: itemWidth,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 18,
                        color: item.color ?? teacherAccent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              item.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: teacherTextSoft,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

class TeacherMetricItem {
  const TeacherMetricItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;
}

class TeacherWorkflow extends StatelessWidget {
  const TeacherWorkflow({super.key, required this.steps});

  final List<TeacherWorkflowStep> steps;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (var index = 0; index < steps.length; index++)
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
          child: _WorkflowStepTile(index: index + 1, step: steps[index]),
        ),
    ],
  );
}

class TeacherWorkflowStep {
  const TeacherWorkflowStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class _WorkflowStepTile extends StatelessWidget {
  const _WorkflowStepTile({required this.index, required this.step});

  final int index;
  final TeacherWorkflowStep step;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.045),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(step.icon, size: 18, color: teacherAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$index. ${step.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          step.description,
          style: const TextStyle(color: teacherTextMuted, height: 1.25),
        ),
      ],
    ),
  );
}

class TeacherNote extends StatelessWidget {
  const TeacherNote({
    super.key,
    required this.icon,
    required this.text,
    this.color = teacherAccent,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFE2E8F0), height: 1.25),
          ),
        ),
      ],
    ),
  );
}
