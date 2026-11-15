import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/assessment_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/store/assessment_store.dart';
import '../../../core/store/authoring_store.dart';
import '../../../core/store/session_store.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  String? _studentId;
  String? _worldId;
  String? _topicId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ReportStore>();
    final session = context.watch<SessionStore>();
    final authoring = context.watch<AuthoringStore>();
    final students = session.users
        .where((user) => user.role == UserRole.student)
        .toList();
    final topics = authoring.topics
        .where((topic) => _worldId == null || topic.worldId == _worldId)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Resultados de aprendizaje',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text(
          'Consulta intentos de entrenamiento y parciales por estudiante, mundo y tema.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                initialValue: _studentId ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Estudiante'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos')),
                  ...students.map(
                    (student) => DropdownMenuItem(
                      value: student.id,
                      child: Text(
                        student.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _studentId = value == null || value.isEmpty ? null : value;
                }),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                initialValue: _worldId ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Mundo'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos')),
                  ...authoring.worlds.map(
                    (world) => DropdownMenuItem(
                      value: world.id,
                      child: Text(world.title, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _worldId = value == null || value.isEmpty ? null : value;
                  if (_topicId != null &&
                      !authoring.topics.any(
                        (topic) =>
                            topic.id == _topicId &&
                            (_worldId == null || topic.worldId == _worldId),
                      )) {
                    _topicId = null;
                  }
                }),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                  'topic-${_worldId ?? 'all'}-${_topicId ?? 'all'}',
                ),
                initialValue: _topicId ?? '',
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tema'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos')),
                  ...topics.map(
                    (topic) => DropdownMenuItem(
                      value: topic.id,
                      child: Text(topic.title, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _topicId = value == null || value.isEmpty ? null : value;
                }),
              ),
            ),
            FilledButton.icon(
              onPressed: store.loading
                  ? null
                  : () => store.load(
                      studentId: _studentId,
                      worldId: _worldId,
                      topicId: _topicId,
                    ),
              icon: const Icon(Icons.filter_alt),
              label: const Text('APLICAR'),
            ),
          ],
        ),
        if (store.error != null) ...[
          const SizedBox(height: 12),
          Text(store.error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 20),
        if (store.loading)
          const Center(child: CircularProgressIndicator())
        else ...[
          _ReportSection(
            title: 'Entrenamiento (${store.report?.training.length ?? 0})',
            emptyMessage: 'No hay intentos de entrenamiento con estos filtros.',
            children:
                store.report?.training
                    .map(
                      (item) => ListTile(
                        leading: Icon(
                          item.isCorrect ? Icons.check_circle : Icons.cancel,
                          color: item.isCorrect
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                        title: Text(
                          '${item.studentName} • ${item.missionTitle}',
                        ),
                        subtitle: Text(
                          '${item.worldTitle} / ${item.topicTitle} • ${item.hintUsed ? 'Usó pista' : 'Sin pista'}',
                        ),
                      ),
                    )
                    .toList() ??
                const [],
          ),
          _ReportSection(
            title: 'Parciales (${store.report?.assessments.length ?? 0})',
            emptyMessage: 'No hay parciales entregados con estos filtros.',
            children:
                store.report?.assessments
                    .map(
                      (item) => ExpansionTile(
                        leading: CircleAvatar(child: Text('${item.score}')),
                        title: Text('${item.studentName} • ${item.worldTitle}'),
                        subtitle: Text(
                          '${item.status.wireName.toUpperCase()} • ${item.passed ? 'APROBADO' : 'NO APROBADO'} • ${item.incidents} incidentes',
                          style: TextStyle(
                            color: item.passed
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                        children: [
                          ...item.topics.map(
                            (topic) => ListTile(
                              title: Text(topic.topicTitle),
                              trailing: Text('${topic.score}/100'),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _showDetail(context, item.id),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('VER DETALLE'),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList() ??
                const [],
          ),
        ],
      ],
    );
  }

  Future<void> _showDetail(BuildContext context, String attemptId) async {
    final store = context.read<ReportStore>();
    await store.loadDetail(attemptId);
    if (!context.mounted || store.detail == null) return;
    final detail = store.detail!;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle • ${detail.attempt.studentName}'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nota ${detail.attempt.score}/100 • ${detail.attempt.status.wireName.toUpperCase()} • ${detail.attempt.incidents} incidentes • ${detail.attempt.durationSeconds ~/ 60} min',
                ),
                const SizedBox(height: 12),
                Text(
                  'Preguntas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...detail.questions.map(
                  (question) => ListTile(
                    leading: Icon(
                      question.isCorrect ? Icons.check_circle : Icons.cancel,
                      color: question.isCorrect
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    title: Text('${question.number}. ${question.prompt}'),
                    subtitle: Text(
                      'Respuesta: ${question.selectedOptionTexts.isEmpty ? 'Sin responder' : question.selectedOptionTexts.join(', ')}\nCorrecta: ${question.correctOptionTexts.join(', ')}',
                    ),
                  ),
                ),
                const Divider(),
                Text(
                  'Incidentes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (detail.events.isEmpty)
                  const Text(
                    'Sin eventos registrados.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  )
                else
                  ...detail.events.map((event) => _EventTile(event: event)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final AssessmentAttemptEvent event;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(_eventIcon(event.type), size: 20),
    title: Text(_eventLabel(event.type)),
    subtitle: Text(
      '${event.occurredAt.toLocal()} • ${event.message}${event.answeredQuestions == null ? '' : ' • ${event.answeredQuestions}/${event.totalQuestions} respondidas'}${event.score == null ? '' : ' • nota ${event.score}'}',
    ),
  );
}

IconData _eventIcon(String type) => switch (type) {
  'fullscreen_exit' ||
  'focus_lost' ||
  'visibility_hidden' ||
  'blocked_key' ||
  'pagehide' => Icons.warning_amber_rounded,
  'annulled' || 'expired' => Icons.gpp_bad_rounded,
  'reactivated' => Icons.restart_alt_rounded,
  'submitted' => Icons.flag_rounded,
  'progress' => Icons.edit_note_rounded,
  _ => Icons.info_outline,
};

String _eventLabel(String type) => switch (type) {
  'fullscreen_exit' => 'Salida de pantalla completa',
  'focus_lost' => 'Pérdida de foco',
  'visibility_hidden' => 'Cambio de pestaña',
  'blocked_key' => 'Tecla bloqueada',
  'pagehide' => 'Salida o recarga',
  'annulled' => 'Anulación',
  'expired' => 'Tiempo agotado',
  'reactivated' => 'Reactivación',
  'submitted' => 'Entrega',
  'progress' => 'Progreso',
  'started' => 'Inicio',
  _ => type,
};

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF1E293B),
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (children.isEmpty)
            Text(emptyMessage, style: const TextStyle(color: Color(0xFF94A3B8)))
          else
            ...children,
        ],
      ),
    ),
  );
}
