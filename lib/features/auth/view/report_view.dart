import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
                          item.passed ? 'APROBADO' : 'NO APROBADO',
                          style: TextStyle(
                            color: item.passed
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                          ),
                        ),
                        children: item.topics
                            .map(
                              (topic) => ListTile(
                                title: Text(topic.topicTitle),
                                trailing: Text('${topic.score}/100'),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList() ??
                const [],
          ),
        ],
      ],
    );
  }
}

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
