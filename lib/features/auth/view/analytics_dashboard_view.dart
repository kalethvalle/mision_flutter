import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/analytics_model.dart';
import '../../../core/store/assessment_store.dart';

class AnalyticsDashboardView extends StatelessWidget {
  const AnalyticsDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AnalyticsStore>();
    final dashboard = store.dashboard;
    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Header(
            refreshedAt: dashboard?.refreshedAt,
            loading: store.loading,
            onRefresh: store.loading ? null : store.refresh,
          ),
          const SizedBox(height: 18),
          if (store.error != null) _ErrorBanner(message: store.error!),
          if (store.loading && dashboard == null)
            const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (dashboard == null)
            const _EmptyState()
          else ...[
            _KpiGrid(summary: dashboard.summary),
            const SizedBox(height: 18),
            _EvolutionSection(items: dashboard.studentEvolution),
            const SizedBox(height: 18),
            _PerformanceSection(items: dashboard.academicPerformance),
            const SizedBox(height: 18),
            _TopicSection(items: dashboard.topicDifficulty),
            const SizedBox(height: 18),
            _IntegritySection(items: dashboard.integrity),
          ],
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.refreshedAt,
    required this.loading,
    required this.onRefresh,
  });

  final DateTime? refreshedAt;
  final bool loading;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métricas de aprendizaje',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              refreshedAt == null
                  ? 'Evolución, rendimiento académico e integridad por estudiante.'
                  : 'Último recálculo: ${_formatDateTime(refreshedAt!)}',
              style: const TextStyle(color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
      ),
      FilledButton.icon(
        onPressed: onRefresh,
        icon: loading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
        label: const Text('RECALCULAR'),
      ),
    ],
  );

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final AnalyticsKpiSummary summary;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1100
          ? 4
          : width >= 760
          ? 3
          : 2;
      final itemWidth = (width - ((columns - 1) * 12)) / columns;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _KpiCard(
            width: itemWidth,
            icon: Icons.groups,
            label: 'Estudiantes',
            value: '${summary.activeStudents}/${summary.totalStudents}',
          ),
          _KpiCard(
            width: itemWidth,
            icon: Icons.flag_circle,
            label: 'Misiones completadas',
            value: '${summary.completedMissions}',
          ),
          _KpiCard(
            width: itemWidth,
            icon: Icons.track_changes,
            label: 'Precisión arena',
            value: '${summary.trainingAccuracy}%',
          ),
          _KpiCard(
            width: itemWidth,
            icon: Icons.school,
            label: 'Promedio parciales',
            value: '${summary.averageAssessmentScore}',
          ),
          _KpiCard(
            width: itemWidth,
            icon: Icons.verified,
            label: 'Aprobación',
            value: '${summary.approvalRate}%',
          ),
          _KpiCard(
            width: itemWidth,
            icon: Icons.assignment,
            label: 'Intentos arena',
            value: '${summary.trainingAttempts}',
          ),
          _KpiCard(
            width: itemWidth,
            icon: Icons.warning_amber,
            label: 'Incidentes',
            value: '${summary.incidents}',
          ),
          _KpiCard(
            width: itemWidth,
            icon: Icons.gpp_bad,
            label: 'Anulados',
            value: '${summary.annulledAttempts}',
          ),
        ],
      );
    },
  );
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF38BDF8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EvolutionSection extends StatelessWidget {
  const _EvolutionSection({required this.items});

  final List<StudentEvolutionMetric> items;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Evolución estudiantil',
    icon: Icons.timeline,
    emptyText: 'Aún no hay actividad estudiantil para analizar.',
    children: items
        .map(
          (item) => _MetricRow(
            title: item.studentName,
            subtitle:
                'Activo ${item.activeDays} días • misiones ${item.completedMissions}/${item.totalMissions}',
            trailing:
                'Arena ${item.trainingAccuracy}% • reciente ${item.recentTrainingAccuracy}% • parcial ${item.latestAssessmentScore}',
          ),
        )
        .toList(),
  );
}

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({required this.items});

  final List<AcademicPerformanceMetric> items;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Rendimiento académico',
    icon: Icons.insights,
    emptyText: 'No hay parciales entregados ni actividad suficiente.',
    children: items
        .map(
          (item) => _MetricRow(
            title: item.studentName,
            subtitle:
                'Parciales ${item.totalAttempts} • aprobados ${item.approvedAttempts}',
            trailing:
                'Prom. ${item.averageScore} • arena ${item.trainingAccuracy}% • brecha ${item.trainingAssessmentGap}',
          ),
        )
        .toList(),
  );
}

class _TopicSection extends StatelessWidget {
  const _TopicSection({required this.items});

  final List<TopicDifficultyMetric> items;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Temas críticos',
    icon: Icons.report_problem,
    emptyText: 'No hay temas con datos evaluables.',
    children: items
        .map(
          (item) => _MetricRow(
            title: item.topicTitle,
            subtitle: item.worldTitle,
            trailing:
                'Arena ${item.trainingAccuracy}% • parcial ${item.assessmentScore} • datos ${item.attempts}',
          ),
        )
        .toList(),
  );
}

class _IntegritySection extends StatelessWidget {
  const _IntegritySection({required this.items});

  final List<IntegrityMetric> items;

  @override
  Widget build(BuildContext context) => _Section(
    title: 'Integridad',
    icon: Icons.security,
    emptyText: 'No hay señales de integridad registradas.',
    children: items
        .map(
          (item) => _MetricRow(
            title: item.studentName,
            subtitle:
                'Incidentes ${item.incidents} • anulados ${item.annulledAttempts} • reactivaciones ${item.reactivations}',
            trailing: 'Riesgo ${item.riskLevel}',
          ),
        )
        .toList(),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final IconData icon;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF1E293B),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF38BDF8)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (children.isEmpty)
            Text(emptyText, style: const TextStyle(color: Color(0xFF94A3B8)))
          else
            ...children,
        ],
      ),
    ),
  );
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 4,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle, style: const TextStyle(color: Color(0xFFCBD5E1))),
            ],
          ),
        ),
        Text(
          trailing,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF7F1D1D),
    child: Padding(padding: const EdgeInsets.all(14), child: Text(message)),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 80),
    child: Center(
      child: Text(
        'No hay métricas disponibles.',
        style: TextStyle(color: Color(0xFFCBD5E1)),
      ),
    ),
  );
}
