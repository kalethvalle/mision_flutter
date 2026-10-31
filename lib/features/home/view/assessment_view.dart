import 'package:flutter/material.dart';

import '../../../core/models/assessment_model.dart';
import '../../../core/models/authoring_model.dart';
import '../../../core/store/assessment_store.dart';

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
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
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

class _AttemptBody extends StatelessWidget {
  const _AttemptBody({required this.store, required this.attempt});

  final AssessmentStore store;
  final AssessmentAttempt attempt;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const _AssessmentHeader(
        icon: Icons.sports_martial_arts,
        title: 'JEFE FINAL',
        message: 'Responde todas las preguntas y entrega cuando estés listo. No hay pistas ni límite de tiempo.',
      ),
      const SizedBox(height: 18),
      ...attempt.questions.asMap().entries.map(
        (entry) => _QuestionCard(
          number: entry.key + 1,
          question: entry.value,
          selected: store.answers[entry.value.id] ?? const {},
          onToggle: (optionId) => store.toggle(entry.value, optionId),
        ),
      ),
      if (store.error != null) ...[
        const SizedBox(height: 8),
        Text(store.error!, style: const TextStyle(color: Colors.redAccent)),
      ],
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: store.isBusy
            ? null
            : () async {
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
                        child: const Text('CANCELAR'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('ENTREGAR'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) await store.submit();
              },
        icon: const Icon(Icons.flag),
        label: Text(store.isBusy ? 'CALIFICANDO…' : 'ENTREGAR PARCIAL'),
      ),
      const SizedBox(height: 28),
    ],
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
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF1E293B),
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PREGUNTA $number • ${question.topicTitle}',
            style: const TextStyle(
              color: Color(0xFF38BDF8),
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
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          ...question.options.map(
            (option) => CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: selected.contains(option.id),
              onChanged: (_) => onToggle(option.id),
              title: Text(option.text),
              controlAffinity: ListTileControlAffinity.leading,
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
          title: result.passed ? '¡JEFE SUPERADO!' : 'SIGUE ENTRENANDO',
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
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF1E293B),
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
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
                    : const Color(0xFFCBD5E1),
              ),
            );
          }),
          const SizedBox(height: 10),
          Text(
            review.explanation,
            style: const TextStyle(color: Color(0xFFBAE6FD)),
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
    this.color = const Color(0xFFA855F7),
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.35), const Color(0xFF1E293B)],
      ),
      borderRadius: BorderRadius.circular(16),
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
              Text(message, style: const TextStyle(color: Color(0xFFCBD5E1))),
            ],
          ),
        ),
      ],
    ),
  );
}
