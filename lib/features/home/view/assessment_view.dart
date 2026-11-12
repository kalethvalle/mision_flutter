import 'package:flutter/material.dart';

import '../../../core/models/assessment_model.dart';
import '../../../core/models/authoring_model.dart';
import '../../../core/store/assessment_store.dart';
import 'assessment_browser_guard.dart';
import 'student_theme.dart';

class AssessmentView extends StatelessWidget {
  const AssessmentView({super.key, required this.store});

  final AssessmentStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final result = store.result;
      final attempt = store.attempt;
      return Scaffold(
        backgroundColor: QuestColors.background,
        appBar: AppBar(
          backgroundColor: QuestColors.surface,
          title: Text(
            result?.worldTitle ?? attempt?.worldTitle ?? 'Jefe final',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: result != null
            ? _ResultBody(result: result)
            : attempt != null
            ? _AttemptBody(store: store, attempt: attempt)
            : const Center(child: CircularProgressIndicator()),
      );
    },
  );
}

class _AttemptBody extends StatefulWidget {
  const _AttemptBody({required this.store, required this.attempt});

  final AssessmentStore store;
  final AssessmentAttempt attempt;

  @override
  State<_AttemptBody> createState() => _AttemptBodyState();
}

class _AttemptBodyState extends State<_AttemptBody> {
  final _guard = AssessmentBrowserGuard();
  AssessmentGuardHandle? _handle;
  bool _ready = false;
  bool _fullscreenWarning = false;

  @override
  void dispose() {
    _handle?.dispose();
    _guard.unlockKeyboard();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready && widget.attempt.settings.fullscreenRequired) {
      return _StartRulesCard(
        attempt: widget.attempt,
        onStart: _enterFullscreen,
      );
    }
    final answered = widget.store.answers.values
        .where((options) => options.isNotEmpty)
        .length;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AssessmentHeader(
              icon: Icons.sports_martial_arts,
              title: 'Jefe final',
              message:
                  'Tiempo hasta ${widget.attempt.deadlineAt.toLocal()} • $answered/${widget.attempt.questions.length} respondidas',
              color: QuestColors.boss,
            ),
            const SizedBox(height: 18),
            ...widget.attempt.questions.asMap().entries.map(
              (entry) => _QuestionCard(
                number: entry.key + 1,
                question: entry.value,
                selected: widget.store.answers[entry.value.id] ?? const {},
                onToggle: (optionId) =>
                    widget.store.toggle(entry.value, optionId),
              ),
            ),
            if (widget.store.error != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.store.error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.store.isBusy ? null : _confirmSubmit,
              icon: const Icon(Icons.flag),
              label: Text(
                widget.store.isBusy ? 'Calificando...' : 'Entregar parcial',
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
        IgnorePointer(
          child: Opacity(
            opacity: 0.08,
            child: Center(
              child: Transform.rotate(
                angle: -0.45,
                child: Text(
                  widget.attempt.worldTitle,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_fullscreenWarning)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.78),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: QuestCard(
                    padding: const EdgeInsets.all(22),
                    borderColor: QuestColors.danger,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning,
                          color: QuestColors.danger,
                          size: 42,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Regresa a pantalla completa',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _enterFullscreen,
                          child: const Text('VOLVER'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _enterFullscreen() async {
    final ok = await _guard.enterFullscreen();
    await _guard.lockEscape();
    if (!mounted) return;
    setState(() {
      _ready = true;
      _fullscreenWarning = false;
    });
    if (!ok) {
      await widget.store.recordIncident(
        'fullscreen_unavailable',
        'El navegador no permitió pantalla completa.',
      );
    }
    _handle ??= _guard.watch(
      onIncident: widget.store.recordIncident,
      onFullscreenExit: () {
        widget.store.recordIncident(
          'fullscreen_exit',
          'Salió de pantalla completa.',
        );
        if (mounted) setState(() => _fullscreenWarning = true);
      },
    );
  }

  Future<void> _confirmSubmit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entregar parcial'),
        content: const Text(
          'Las preguntas sin respuesta contarán como incorrectas y el intento no podrá modificarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Entregar'),
          ),
        ],
      ),
    );
    if (confirm == true) await widget.store.submit();
  }
}

class _StartRulesCard extends StatelessWidget {
  const _StartRulesCard({required this.attempt, required this.onStart});

  final AssessmentAttempt attempt;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: QuestCard(
        padding: const EdgeInsets.all(24),
        borderColor: QuestColors.boss,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.fullscreen, color: QuestColors.boss, size: 52),
            const SizedBox(height: 12),
            const Text(
              'Parcial controlado',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Duración: ${attempt.settings.durationMinutes} min. Debes mantener pantalla completa; las salidas o teclas bloqueadas pueden anular el intento.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: QuestColors.muted),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow),
              label: const Text('INICIAR EN PANTALLA COMPLETA'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.number,
    required this.question,
    required this.selected,
    required this.onToggle,
  });

  final int number;
  final AssessmentQuestion question;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: QuestCard(
      borderColor: selected.isEmpty
          ? QuestColors.border
          : QuestColors.boss.withValues(alpha: 0.75),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pregunta $number - ${question.topicTitle}',
            style: const TextStyle(
              color: QuestColors.boss,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.prompt,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            question.type == QuestionType.single
                ? 'Selecciona una opción.'
                : 'Selecciona todas las opciones correctas.',
            style: const TextStyle(color: QuestColors.muted),
          ),
          const SizedBox(height: 12),
          ...question.options.map(
            (option) => Material(
              type: MaterialType.transparency,
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selected.contains(option.id),
                onChanged: (_) => onToggle(option.id),
                title: Text(option.text),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result});

  final AssessmentResult result;

  @override
  Widget build(BuildContext context) {
    final color = result.passed ? const Color(0xFF10B981) : Colors.orange;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AssessmentHeader(
          icon: result.passed ? Icons.emoji_events : Icons.replay,
          title: result.passed ? 'Jefe superado' : 'Sigue entrenando',
          message:
              '${result.score}/100 • ${result.correctAnswers}/${result.totalQuestions} respuestas correctas',
          color: color,
        ),
        const SizedBox(height: 18),
        Text(
          'Desglose por tema',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: result.topics
              .map(
                (topic) => Chip(
                  label: Text('${topic.topicTitle}: ${topic.score}/100'),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        Text('Revisión', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...result.reviews.asMap().entries.map(
          (entry) => _ReviewCard(number: entry.key + 1, review: entry.value),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.number, required this.review});

  final int number;
  final AssessmentReview review;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: QuestCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                review.isCorrect ? Icons.check_circle : Icons.cancel,
                color: review.isCorrect ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$number. ${review.prompt}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...review.options.map((option) {
            final selected = review.selectedOptionIds.contains(option.id);
            final correct = review.correctOptionIds.contains(option.id);
            return Text(
              '${correct
                  ? '✓'
                  : selected
                  ? '✗'
                  : '•'} ${option.text}${selected ? ' (tu selección)' : ''}',
              style: TextStyle(
                color: correct
                    ? Colors.greenAccent
                    : selected
                    ? Colors.redAccent
                    : QuestColors.text,
              ),
            );
          }),
          const SizedBox(height: 10),
          Text(
            review.explanation,
            style: const TextStyle(color: QuestColors.training),
          ),
        ],
      ),
    ),
  );
}

class _AssessmentHeader extends StatelessWidget {
  const _AssessmentHeader({
    required this.icon,
    required this.title,
    required this.message,
    this.color = QuestColors.boss,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: QuestColors.surfaceRaised,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Row(
      children: [
        Icon(icon, size: 48, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(message, style: const TextStyle(color: QuestColors.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}
