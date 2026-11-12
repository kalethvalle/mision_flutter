import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/assessment_model.dart';
import '../../../core/models/authoring_model.dart';
import '../../../core/store/assessment_store.dart';
import '../../../core/store/authoring_store.dart';

class AssessmentSessionView extends StatefulWidget {
  const AssessmentSessionView({super.key});

  @override
  State<AssessmentSessionView> createState() => _AssessmentSessionViewState();
}

class _AssessmentSessionViewState extends State<AssessmentSessionView> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) context.read<AssessmentSessionStore>().load();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AssessmentSessionStore>();
    final authoring = context.watch<AuthoringStore>();
    final overview = store.overview;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Parciales controlados',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const Text(
          'Activa el parcial por mundo, controla el tiempo y revisa incidentes en vivo.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        if (store.error != null) ...[
          const SizedBox(height: 12),
          Text(store.error!, style: const TextStyle(color: Colors.redAccent)),
        ],
        const SizedBox(height: 18),
        if (store.loading && overview == null)
          const Center(child: CircularProgressIndicator())
        else
          ...authoring.worlds.map((world) {
            final settings =
                overview?.settings
                    .where((item) => item.worldId == world.id)
                    .firstOrNull ??
                AssessmentWorldSettings.defaults(world.id!);
            final session = overview?.sessions
                .where(
                  (item) =>
                      item.worldId == world.id &&
                      item.status == AssessmentSessionStatus.open,
                )
                .firstOrNull;
            return _WorldSessionCard(
              world: world,
              settings: settings,
              session: session,
              busy: store.loading,
            );
          }),
      ],
    );
  }
}

class _WorldSessionCard extends StatefulWidget {
  const _WorldSessionCard({
    required this.world,
    required this.settings,
    required this.session,
    required this.busy,
  });

  final AuthoringWorld world;
  final AssessmentWorldSettings settings;
  final AssessmentSession? session;
  final bool busy;

  @override
  State<_WorldSessionCard> createState() => _WorldSessionCardState();
}

class _WorldSessionCardState extends State<_WorldSessionCard> {
  late final _duration = TextEditingController(
    text: '${widget.settings.durationMinutes}',
  );
  late final _maxIncidents = TextEditingController(
    text: '${widget.settings.maxIncidents}',
  );
  late final _grace = TextEditingController(
    text: '${widget.settings.returnGraceSeconds}',
  );
  late bool _fullscreen = widget.settings.fullscreenRequired;
  late bool _strict = widget.settings.strictMode;

  @override
  void dispose() {
    _duration.dispose();
    _maxIncidents.dispose();
    _grace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.session != null;
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.world.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(active ? 'ACTIVO' : 'CERRADO'),
                  backgroundColor: active
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.white10,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SmallNumberField(label: 'Minutos', controller: _duration),
                _SmallNumberField(
                  label: 'Incidentes',
                  controller: _maxIncidents,
                ),
                _SmallNumberField(label: 'Retorno s', controller: _grace),
                FilterChip(
                  label: const Text('Pantalla completa'),
                  selected: _fullscreen,
                  onSelected: (value) => setState(() => _fullscreen = value),
                ),
                FilterChip(
                  label: const Text('Estricto'),
                  selected: _strict,
                  onSelected: (value) => setState(() => _strict = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: widget.busy ? null : _save,
                  icon: const Icon(Icons.save),
                  label: const Text('GUARDAR CONFIGURACIÓN'),
                ),
                FilledButton.icon(
                  onPressed: widget.busy || active ? null : _open,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('ACTIVAR'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.busy || !active ? null : _close,
                  icon: const Icon(Icons.stop),
                  label: const Text('CERRAR'),
                ),
              ],
            ),
            if (widget.session != null) ...[
              const Divider(height: 28),
              Text(
                'Cierra: ${widget.session!.closesAt.toLocal()}',
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 8),
              ...widget.session!.attempts.map(
                (attempt) => _LiveAttemptTile(attempt: attempt),
              ),
              if (widget.session!.attempts.isEmpty)
                const Text(
                  'Aún no hay estudiantes respondiendo.',
                  style: TextStyle(color: Color(0xFF94A3B8)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    await context.read<AssessmentSessionStore>().saveSettings(
      AssessmentWorldSettings(
        worldId: widget.world.id!,
        durationMinutes: int.tryParse(_duration.text) ?? 20,
        fullscreenRequired: _fullscreen,
        maxIncidents: int.tryParse(_maxIncidents.text) ?? 2,
        returnGraceSeconds: int.tryParse(_grace.text) ?? 10,
        strictMode: _strict,
      ),
    );
  }

  Future<void> _open() =>
      context.read<AssessmentSessionStore>().open(widget.world.id!);

  Future<void> _close() =>
      context.read<AssessmentSessionStore>().close(widget.session!.id);
}

class _LiveAttemptTile extends StatelessWidget {
  const _LiveAttemptTile({required this.attempt});

  final AssessmentLiveAttempt attempt;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(child: Text('${attempt.answeredQuestions}')),
    title: Text(attempt.studentName),
    subtitle: Text(
      '${attempt.status.wireName} • ${attempt.answeredQuestions}/${attempt.totalQuestions} respondidas • ${attempt.incidents} incidentes${attempt.score == null ? '' : ' • nota ${attempt.score}'}',
    ),
    trailing: attempt.status == AssessmentAttemptStatus.annulled
        ? OutlinedButton(
            onPressed: () => _reactivate(context),
            child: const Text('REACTIVAR'),
          )
        : null,
  );

  Future<void> _reactivate(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reactivar intento'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Motivo'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reactivar'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    await context.read<AssessmentSessionStore>().reactivate(
      attempt.attemptId,
      reason.trim(),
    );
  }
}

class _SmallNumberField extends StatelessWidget {
  const _SmallNumberField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
