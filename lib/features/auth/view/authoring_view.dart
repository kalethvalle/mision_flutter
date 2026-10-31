import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/authoring_model.dart';
import '../../../core/models/mission_model.dart';
import '../../../core/store/authoring_store.dart';

class ContentAuthoringView extends StatelessWidget {
  const ContentAuthoringView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AuthoringStore>();
    if (store.state == AuthoringState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (store.state == AuthoringState.failure) {
      return _LoadFailure(message: store.error, retry: store.load);
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ActionBar(
          title: 'Editor de contenido',
          subtitle: 'Mundos, temas y misiones basadas en plantillas seguras.',
          actions: [
            FilledButton.icon(
              onPressed: () => _showWorld(context, store),
              icon: const Icon(Icons.public),
              label: const Text('NUEVO MUNDO'),
            ),
            FilledButton.icon(
              onPressed: store.worlds.isEmpty
                  ? null
                  : () => _showTopic(context, store),
              icon: const Icon(Icons.category),
              label: const Text('NUEVO TEMA'),
            ),
            FilledButton.icon(
              onPressed: store.topics.isEmpty
                  ? null
                  : () => _showMission(context, store),
              icon: const Icon(Icons.extension),
              label: const Text('NUEVA MISIÓN'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Mundos (${store.worlds.length})',
          children: store.worlds
              .map(
                (world) => _AuthoringTile(
                  title: world.title.isEmpty ? 'Mundo sin título' : world.title,
                  subtitle: 'Orden ${world.sortOrder} • ${world.iconKey}',
                  status: world.status,
                  onEdit: () => _showWorld(context, store, world),
                ),
              )
              .toList(),
        ),
        _Section(
          title: 'Temas (${store.topics.length})',
          children: store.topics
              .map(
                (topic) => _AuthoringTile(
                  title: topic.title.isEmpty ? 'Tema sin título' : topic.title,
                  subtitle:
                      '${_worldName(store, topic.worldId)} • Orden ${topic.sortOrder}',
                  status: topic.status,
                  onEdit: () => _showTopic(context, store, topic),
                ),
              )
              .toList(),
        ),
        _Section(
          title: 'Misiones (${store.missions.length})',
          children: store.missions
              .map(
                (mission) => _AuthoringTile(
                  title: mission.title.isEmpty
                      ? 'Misión sin título'
                      : mission.title,
                  subtitle:
                      '${_worldName(store, mission.worldId)} • v${mission.contentVersion} • ${mission.previewType}',
                  status: mission.status,
                  onEdit: () => _showMission(context, store, mission),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _showWorld(
    BuildContext context,
    AuthoringStore store, [
    AuthoringWorld? world,
  ]) {
    store.clearError();
    showDialog<void>(
      context: context,
      builder: (_) => _WorldDialog(store: store, initial: world),
    );
  }

  void _showTopic(
    BuildContext context,
    AuthoringStore store, [
    AuthoringTopic? topic,
  ]) {
    store.clearError();
    showDialog<void>(
      context: context,
      builder: (_) => _TopicDialog(store: store, initial: topic),
    );
  }

  void _showMission(
    BuildContext context,
    AuthoringStore store, [
    AuthoringMission? mission,
  ]) {
    store.clearError();
    showDialog<void>(
      context: context,
      builder: (_) => _MissionDialog(store: store, initial: mission),
    );
  }
}

class QuestionBankView extends StatelessWidget {
  const QuestionBankView({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AuthoringStore>();
    if (store.state == AuthoringState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (store.state == AuthoringState.failure) {
      return _LoadFailure(message: store.error, retry: store.load);
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ActionBar(
          title: 'Banco de preguntas',
          subtitle: 'Preguntas versionadas para los parciales de cada tema.',
          actions: [
            FilledButton.icon(
              onPressed: store.topics.isEmpty
                  ? null
                  : () {
                      store.clearError();
                      showDialog<void>(
                        context: context,
                        builder: (_) => _QuestionDialog(store: store),
                      );
                    },
              icon: const Icon(Icons.quiz),
              label: const Text('NUEVA PREGUNTA'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Section(
          title: 'Preguntas (${store.questions.length})',
          children: store.questions.isEmpty
              ? const [
                  ListTile(
                    title: Text('Aún no hay preguntas.'),
                    subtitle: Text('Crea un borrador para comenzar el banco.'),
                  ),
                ]
              : store.questions
                    .map(
                      (question) => _AuthoringTile(
                        title: question.prompt.isEmpty
                            ? 'Pregunta sin enunciado'
                            : question.prompt,
                        subtitle:
                            '${_worldName(store, question.worldId)} • ${question.type.wireName} • v${question.contentVersion}',
                        status: question.status,
                        onEdit: () {
                          store.clearError();
                          showDialog<void>(
                            context: context,
                            builder: (_) => _QuestionDialog(
                              store: store,
                              initial: question,
                            ),
                          );
                        },
                      ),
                    )
                    .toList(),
        ),
      ],
    );
  }
}

class _WorldDialog extends StatefulWidget {
  const _WorldDialog({required this.store, this.initial});

  final AuthoringStore store;
  final AuthoringWorld? initial;

  @override
  State<_WorldDialog> createState() => _WorldDialogState();
}

class _WorldDialogState extends State<_WorldDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _color;
  late final TextEditingController _order;
  late String _icon;
  late ContentStatus _status;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _title = TextEditingController(text: value?.title);
    _description = TextEditingController(text: value?.description);
    _color = TextEditingController(text: value?.colorHex ?? '#38BDF8');
    _order = TextEditingController(
      text: '${value?.sortOrder ?? widget.store.worlds.length + 1}',
    );
    _icon = value?.iconKey ?? 'public';
    _status = value?.status ?? ContentStatus.draft;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _color.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EditorDialog(
    title: widget.initial == null ? 'Nuevo mundo' : 'Editar mundo',
    store: widget.store,
    onSave: _save,
    children: [
      _field(_title, 'Título'),
      _field(_description, 'Descripción', lines: 3),
      DropdownButtonFormField<String>(
        initialValue: _icon,
        decoration: const InputDecoration(labelText: 'Icono'),
        items: const ['code', 'widgets', 'public']
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: (value) => setState(() => _icon = value!),
      ),
      _field(_color, 'Color hexadecimal'),
      _field(_order, 'Orden', number: true),
      _statusField(_status, (value) => setState(() => _status = value)),
    ],
  );

  Future<bool> _save() => widget.store.saveWorld(
    AuthoringWorld(
      id: widget.initial?.id,
      title: _title.text,
      description: _description.text,
      iconKey: _icon,
      colorHex: _color.text,
      sortOrder: int.tryParse(_order.text) ?? 0,
      status: _status,
    ),
  );
}

class _TopicDialog extends StatefulWidget {
  const _TopicDialog({required this.store, this.initial});

  final AuthoringStore store;
  final AuthoringTopic? initial;

  @override
  State<_TopicDialog> createState() => _TopicDialogState();
}

class _TopicDialogState extends State<_TopicDialog> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _order;
  late String _worldId;
  late ContentStatus _status;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    _title = TextEditingController(text: value?.title);
    _description = TextEditingController(text: value?.description);
    _order = TextEditingController(text: '${value?.sortOrder ?? 1}');
    _worldId = value?.worldId ?? widget.store.worlds.first.id!;
    _status = value?.status ?? ContentStatus.draft;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _EditorDialog(
    title: widget.initial == null ? 'Nuevo tema' : 'Editar tema',
    store: widget.store,
    onSave: _save,
    children: [
      _worldField(widget.store, _worldId, (value) {
        setState(() => _worldId = value);
      }),
      _field(_title, 'Título'),
      _field(_description, 'Descripción', lines: 3),
      _field(_order, 'Orden dentro del mundo', number: true),
      _statusField(_status, (value) => setState(() => _status = value)),
    ],
  );

  Future<bool> _save() => widget.store.saveTopic(
    AuthoringTopic(
      id: widget.initial?.id,
      worldId: _worldId,
      title: _title.text,
      description: _description.text,
      sortOrder: int.tryParse(_order.text) ?? 0,
      status: _status,
    ),
  );
}

class _MissionDialog extends StatefulWidget {
  const _MissionDialog({required this.store, this.initial});

  final AuthoringStore store;
  final AuthoringMission? initial;

  @override
  State<_MissionDialog> createState() => _MissionDialogState();
}

class _MissionDialogState extends State<_MissionDialog> {
  late final List<TextEditingController> _text;
  late String _worldId;
  late String _topicId;
  late MissionCategory _category;
  late String _previewType;
  late ContentStatus _status;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    final firstTopic = widget.store.topics.first;
    _worldId = value?.worldId ?? firstTopic.worldId;
    _topicId = value?.topicId ?? firstTopic.id!;
    _category = value?.category ?? MissionCategory.dartBasics;
    _previewType = value?.previewType ?? widget.store.previewTypes.first;
    _status = value?.status ?? ContentStatus.draft;
    _text = [
      value?.title ?? '',
      value?.description ?? '',
      _at(value?.paragraphs, 0),
      _at(value?.paragraphs, 1),
      _at(value?.instructions, 0),
      _at(value?.instructions, 1),
      _at(value?.instructions, 2),
      value?.hint ?? '',
      value?.codeTemplate.join('\n') ?? '',
      value?.targetPlaceholder ?? '{{ANSWER}}',
      '${value?.sortOrder ?? 1}',
      value?.options
              .map((item) => '${item.id}|${item.label}|${item.codeSnippet}')
              .join('\n') ??
          '',
      value?.options
              .where((item) => item.isCorrect)
              .map((item) => item.id)
              .firstOrNull ??
          '',
    ].map((value) => TextEditingController(text: value)).toList();
  }

  @override
  void dispose() {
    for (final controller in _text) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.store.topics
        .where((topic) => topic.worldId == _worldId)
        .toList();
    return _EditorDialog(
      title: widget.initial == null
          ? 'Nueva misión'
          : 'Editar misión • v${widget.initial!.contentVersion}',
      store: widget.store,
      onSave: _save,
      children: [
        _worldField(widget.store, _worldId, (value) {
          final matching = widget.store.topics
              .where((topic) => topic.worldId == value)
              .toList();
          setState(() {
            _worldId = value;
            if (matching.isNotEmpty) _topicId = matching.first.id!;
          });
        }),
        DropdownButtonFormField<String>(
          initialValue: topics.any((topic) => topic.id == _topicId)
              ? _topicId
              : null,
          decoration: const InputDecoration(labelText: 'Tema'),
          items: topics
              .map(
                (topic) => DropdownMenuItem(
                  value: topic.id,
                  child: Text(topic.title.isEmpty ? 'Sin título' : topic.title),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _topicId = value!),
        ),
        _field(_text[0], 'Título'),
        _field(_text[1], 'Objetivo', lines: 2),
        _field(_text[2], 'Párrafo conceptual', lines: 3),
        _field(_text[3], 'Aplicación de la misión', lines: 3),
        _field(_text[4], 'Paso 1', lines: 2),
        _field(_text[5], 'Paso 2', lines: 2),
        _field(_text[6], 'Paso 3', lines: 2),
        _field(_text[7], 'Pista', lines: 2),
        DropdownButtonFormField<MissionCategory>(
          initialValue: _category,
          decoration: const InputDecoration(labelText: 'Categoría'),
          items: MissionCategory.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.wireName)),
              )
              .toList(),
          onChanged: (value) => setState(() => _category = value!),
        ),
        DropdownButtonFormField<String>(
          initialValue: _previewType,
          decoration: const InputDecoration(labelText: 'Vista previa'),
          items: widget.store.previewTypes
              .map(
                (value) => DropdownMenuItem(value: value, child: Text(value)),
              )
              .toList(),
          onChanged: (value) => setState(() => _previewType = value!),
        ),
        _field(_text[8], 'Plantilla de código', lines: 5),
        _field(_text[9], 'Marcador de respuesta'),
        _field(_text[10], 'Orden', number: true),
        _field(
          _text[11],
          'Opciones: id|etiqueta|código (una por línea)',
          lines: 5,
        ),
        _field(_text[12], 'ID de la opción correcta'),
        _statusField(_status, (value) => setState(() => _status = value)),
      ],
    );
  }

  Future<bool> _save() {
    final options = _parseMissionOptions(_text[11].text, _text[12].text);
    return widget.store.saveMission(
      AuthoringMission(
        id: widget.initial?.id,
        worldId: _worldId,
        topicId: _topicId,
        title: _text[0].text,
        description: _text[1].text,
        paragraphs: [_text[2].text, _text[3].text],
        instructions: [_text[4].text, _text[5].text, _text[6].text],
        hint: _text[7].text,
        category: _category,
        codeTemplate: _nonEmptyLines(_text[8].text),
        targetPlaceholder: _text[9].text,
        previewType: _previewType,
        sortOrder: int.tryParse(_text[10].text) ?? 0,
        status: _status,
        contentVersion: widget.initial?.contentVersion ?? 1,
        options: options,
      ),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog({required this.store, this.initial});

  final AuthoringStore store;
  final AuthoringQuestion? initial;

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  late final TextEditingController _prompt;
  late final TextEditingController _explanation;
  late final TextEditingController _options;
  late final TextEditingController _correct;
  late String _worldId;
  late String _topicId;
  late QuestionType _type;
  late ContentStatus _status;

  @override
  void initState() {
    super.initState();
    final value = widget.initial;
    final firstTopic = widget.store.topics.first;
    _worldId = value?.worldId ?? firstTopic.worldId;
    _topicId = value?.topicId ?? firstTopic.id!;
    _type = value?.type ?? QuestionType.single;
    _status = value?.status ?? ContentStatus.draft;
    _prompt = TextEditingController(text: value?.prompt);
    _explanation = TextEditingController(text: value?.explanation);
    _options = TextEditingController(
      text: value?.options.map((item) => '${item.id}|${item.text}').join('\n'),
    );
    _correct = TextEditingController(
      text: value?.options
          .where((item) => item.isCorrect)
          .map((item) => item.id)
          .join(','),
    );
  }

  @override
  void dispose() {
    _prompt.dispose();
    _explanation.dispose();
    _options.dispose();
    _correct.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topics = widget.store.topics
        .where((topic) => topic.worldId == _worldId)
        .toList();
    return _EditorDialog(
      title: widget.initial == null
          ? 'Nueva pregunta'
          : 'Editar pregunta • v${widget.initial!.contentVersion}',
      store: widget.store,
      onSave: _save,
      children: [
        _worldField(widget.store, _worldId, (value) {
          final matching = widget.store.topics
              .where((topic) => topic.worldId == value)
              .toList();
          setState(() {
            _worldId = value;
            if (matching.isNotEmpty) _topicId = matching.first.id!;
          });
        }),
        DropdownButtonFormField<String>(
          initialValue: topics.any((topic) => topic.id == _topicId)
              ? _topicId
              : null,
          decoration: const InputDecoration(labelText: 'Tema'),
          items: topics
              .map(
                (topic) => DropdownMenuItem(
                  value: topic.id,
                  child: Text(topic.title.isEmpty ? 'Sin título' : topic.title),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _topicId = value!),
        ),
        _field(_prompt, 'Enunciado', lines: 3),
        DropdownButtonFormField<QuestionType>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: QuestionType.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(
                    value == QuestionType.single ? 'Única' : 'Múltiple',
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _type = value!),
        ),
        _field(_explanation, 'Explicación posterior', lines: 3),
        _field(_options, 'Opciones: id|texto (una por línea)', lines: 5),
        _field(_correct, 'IDs correctos separados por coma'),
        _statusField(_status, (value) => setState(() => _status = value)),
      ],
    );
  }

  Future<bool> _save() => widget.store.saveQuestion(
    AuthoringQuestion(
      id: widget.initial?.id,
      worldId: _worldId,
      topicId: _topicId,
      prompt: _prompt.text,
      type: _type,
      explanation: _explanation.text,
      status: _status,
      contentVersion: widget.initial?.contentVersion ?? 1,
      options: _parseQuestionOptions(_options.text, _correct.text),
    ),
  );
}

class _EditorDialog extends StatelessWidget {
  const _EditorDialog({
    required this.title,
    required this.store,
    required this.onSave,
    required this.children,
  });

  final String title;
  final AuthoringStore store;
  final Future<bool> Function() onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...children.expand(
                (widget) => [widget, const SizedBox(height: 12)],
              ),
              if (store.error != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    store.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: store.isSaving ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        FilledButton(
          onPressed: store.isSaving
              ? null
              : () async {
                  final saved = await onSave();
                  if (saved && context.mounted) Navigator.pop(context);
                },
          child: Text(store.isSaving ? 'GUARDANDO…' : 'GUARDAR'),
        ),
      ],
    ),
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    runSpacing: 12,
    spacing: 20,
    children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8))),
          ],
        ),
      ),
      Wrap(spacing: 8, runSpacing: 8, children: actions),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
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
            const Text('Sin registros.', style: TextStyle(color: Colors.grey))
          else
            ...children,
        ],
      ),
    ),
  );
}

class _AuthoringTile extends StatelessWidget {
  const _AuthoringTile({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final ContentStatus status;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
    subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    leading: Chip(
      label: Text(status == ContentStatus.published ? 'PUBLICADO' : 'BORRADOR'),
      backgroundColor: status == ContentStatus.published
          ? const Color(0xFF065F46)
          : const Color(0xFF334155),
    ),
    trailing: IconButton(
      onPressed: onEdit,
      icon: const Icon(Icons.edit),
      tooltip: 'Editar',
    ),
  );
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.message, required this.retry});

  final String? message;
  final Future<void> Function() retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message ?? 'No fue posible cargar el contenido.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: retry, child: const Text('REINTENTAR')),
      ],
    ),
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  int lines = 1,
  bool number = false,
}) => TextFormField(
  controller: controller,
  maxLines: lines,
  keyboardType: number ? TextInputType.number : TextInputType.multiline,
  decoration: InputDecoration(labelText: label, alignLabelWithHint: lines > 1),
);

Widget _statusField(
  ContentStatus value,
  ValueChanged<ContentStatus> onChanged,
) => DropdownButtonFormField<ContentStatus>(
  initialValue: value,
  decoration: const InputDecoration(labelText: 'Estado'),
  items: ContentStatus.values
      .map(
        (status) => DropdownMenuItem(
          value: status,
          child: Text(
            status == ContentStatus.published ? 'Publicado' : 'Borrador',
          ),
        ),
      )
      .toList(),
  onChanged: (status) => onChanged(status!),
);

Widget _worldField(
  AuthoringStore store,
  String value,
  ValueChanged<String> onChanged,
) => DropdownButtonFormField<String>(
  initialValue: value,
  decoration: const InputDecoration(labelText: 'Mundo'),
  items: store.worlds
      .map(
        (world) => DropdownMenuItem(
          value: world.id,
          child: Text(world.title.isEmpty ? 'Sin título' : world.title),
        ),
      )
      .toList(),
  onChanged: (world) => onChanged(world!),
);

String _worldName(AuthoringStore store, String id) =>
    store.worlds
        .where((world) => world.id == id)
        .map((world) => world.title)
        .firstOrNull ??
    id;

String _at(List<String>? values, int index) =>
    values != null && index < values.length ? values[index] : '';

List<String> _nonEmptyLines(String value) => value
    .split('\n')
    .where((line) => line.trim().isNotEmpty)
    .toList(growable: false);

List<AuthoringMissionOption> _parseMissionOptions(
  String value,
  String correctId,
) {
  return _nonEmptyLines(value).map((line) {
    final first = line.indexOf('|');
    final second = first < 0 ? -1 : line.indexOf('|', first + 1);
    final id = first < 0 ? line.trim() : line.substring(0, first).trim();
    final label = second < 0 ? '' : line.substring(first + 1, second).trim();
    final code = second < 0 ? '' : line.substring(second + 1).trim();
    return AuthoringMissionOption(
      id: id,
      label: label,
      codeSnippet: code,
      isCorrect: id == correctId.trim(),
    );
  }).toList();
}

List<AuthoringQuestionOption> _parseQuestionOptions(
  String value,
  String correctIds,
) {
  final correct = correctIds
      .split(',')
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet();
  return _nonEmptyLines(value).map((line) {
    final separator = line.indexOf('|');
    final id = separator < 0
        ? line.trim()
        : line.substring(0, separator).trim();
    final text = separator < 0 ? '' : line.substring(separator + 1).trim();
    return AuthoringQuestionOption(
      id: id,
      text: text,
      isCorrect: correct.contains(id),
    );
  }).toList();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
