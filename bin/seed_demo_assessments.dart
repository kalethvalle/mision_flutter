import 'dart:io';

import 'package:mision_flutter/server/database/catalog_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final databasePath =
      _option(args, '--database') ?? 'data/flutter_quest.sqlite3';
  final catalog = CatalogDatabase.open(databasePath);
  try {
    final inserted = seedDemoAssessments(catalog.database);
    stdout.writeln(
      'Preguntas demo publicadas: $inserted en ${catalog.databasePath}',
    );
  } finally {
    catalog.close();
  }
}

int seedDemoAssessments(Database database) {
  var count = 0;
  for (final question in _demoQuestions) {
    database.execute(
      '''
      INSERT INTO questions(
        id, world_id, topic_id, prompt, question_type, explanation,
        status, content_version, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, 'published', 1, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        world_id = excluded.world_id,
        topic_id = excluded.topic_id,
        prompt = excluded.prompt,
        question_type = excluded.question_type,
        explanation = excluded.explanation,
        status = 'published',
        updated_at = excluded.updated_at
    ''',
      [
        question.id,
        question.worldId,
        question.topicId,
        question.prompt,
        question.type,
        question.explanation,
        question.createdAt,
        question.createdAt,
      ],
    );
    database.execute('DELETE FROM question_options WHERE question_id = ?', [
      question.id,
    ]);
    for (var index = 0; index < question.options.length; index++) {
      final option = question.options[index];
      database.execute(
        '''
        INSERT INTO question_options(
          question_id, id, text, sort_order, is_correct
        ) VALUES (?, ?, ?, ?, ?)
      ''',
        [
          question.id,
          option.id,
          option.text,
          index + 1,
          option.isCorrect ? 1 : 0,
        ],
      );
    }
    count++;
  }
  return count;
}

String? _option(List<String> args, String name) {
  final equals = args.where((arg) => arg.startsWith('$name='));
  if (equals.isNotEmpty) return equals.first.substring(name.length + 1);
  final index = args.indexOf(name);
  if (index >= 0 && index + 1 < args.length) return args[index + 1];
  return null;
}

class _DemoQuestion {
  const _DemoQuestion({
    required this.id,
    required this.worldId,
    required this.topicId,
    required this.prompt,
    required this.type,
    required this.explanation,
    required this.options,
  });

  final String id;
  final String worldId;
  final String topicId;
  final String prompt;
  final String type;
  final String explanation;
  final List<_DemoOption> options;
  String get createdAt => '2026-11-02T00:00:00.000Z';
}

class _DemoOption {
  const _DemoOption(this.id, this.text, this.isCorrect);

  final String id;
  final String text;
  final bool isCorrect;
}

const _demoQuestions = [
  _DemoQuestion(
    id: 'demo_w1_q1',
    worldId: 'world_1',
    topicId: 'dart_numeric_types',
    prompt: 'Que tipo representa mejor una vida inicial de 100 puntos?',
    type: 'single',
    explanation:
        'int modela enteros sin parte decimal, como 100 puntos de vida.',
    options: [
      _DemoOption('a', 'int', true),
      _DemoOption('b', 'double', false),
      _DemoOption('c', 'String', false),
    ],
  ),
  _DemoQuestion(
    id: 'demo_w1_q2',
    worldId: 'world_1',
    topicId: 'dart_final',
    prompt:
        'Que palabra evita reasignar el nombre del heroe despues de crearlo?',
    type: 'single',
    explanation:
        'final permite asignar una vez y bloquea reasignaciones posteriores.',
    options: [
      _DemoOption('a', 'final', true),
      _DemoOption('b', 'var', false),
      _DemoOption('c', 'dynamic', false),
    ],
  ),
  _DemoQuestion(
    id: 'demo_w1_q3',
    worldId: 'world_1',
    topicId: 'dart_arrow_functions',
    prompt: 'Cuando conviene usar una funcion flecha en Dart?',
    type: 'single',
    explanation: 'La sintaxis => expresa funciones de una sola expresion.',
    options: [
      _DemoOption('a', 'Cuando el cuerpo retorna una sola expresion.', true),
      _DemoOption('b', 'Cuando hay varias sentencias y ciclos.', false),
      _DemoOption('c', 'Solo para funciones asincronas.', false),
    ],
  ),
  _DemoQuestion(
    id: 'demo_w1_q4',
    worldId: 'world_1',
    topicId: 'dart_typed_lists',
    prompt: 'Cuales declaraciones describen una lista tipada de textos?',
    type: 'multiple',
    explanation:
        'List<String> conserva orden y restringe sus elementos a texto.',
    options: [
      _DemoOption('a', 'Usa List<String>.', true),
      _DemoOption('b', 'Mantiene un orden de elementos.', true),
      _DemoOption('c', 'Acepta claves y valores como Map.', false),
    ],
  ),
  _DemoQuestion(
    id: 'demo_w1_q5',
    worldId: 'world_1',
    topicId: 'dart_null_safety',
    prompt: 'Como declaras un texto que tambien puede estar ausente?',
    type: 'single',
    explanation:
        'El sufijo ? permite que el tipo acepte null de forma explicita.',
    options: [
      _DemoOption('a', 'String?', true),
      _DemoOption('b', 'String!', false),
      _DemoOption('c', 'String', false),
    ],
  ),
  _DemoQuestion(
    id: 'demo_w2_q1',
    worldId: 'world_2',
    topicId: 'flutter_row',
    prompt: 'Que alineacion deja espacio entre tres widgets de un Row?',
    type: 'single',
    explanation:
        'spaceBetween coloca el espacio libre entre hijos, no en los extremos.',
    options: [
      _DemoOption('a', 'MainAxisAlignment.spaceBetween', true),
      _DemoOption('b', 'MainAxisAlignment.center', false),
      _DemoOption('c', 'MainAxisAlignment.end', false),
    ],
  ),
  _DemoQuestion(
    id: 'demo_w2_q2',
    worldId: 'world_2',
    topicId: 'flutter_column',
    prompt: 'Que valor mueve un hijo al final del eje vertical en Column?',
    type: 'single',
    explanation: 'En Column, el eje principal es vertical y end apunta abajo.',
    options: [
      _DemoOption('a', 'MainAxisAlignment.end', true),
      _DemoOption('b', 'MainAxisAlignment.start', false),
      _DemoOption('c', 'MainAxisAlignment.center', false),
    ],
  ),
  _DemoQuestion(
    id: 'demo_w2_q3',
    worldId: 'world_2',
    topicId: 'flutter_padding',
    prompt: 'Cuales afirmaciones aplican a EdgeInsets.all(32)?',
    type: 'multiple',
    explanation:
        'EdgeInsets.all aplica el mismo espacio interno a los cuatro lados.',
    options: [
      _DemoOption('a', 'Agrega espacio interno.', true),
      _DemoOption('b', 'Usa 32 pixeles en cada lado.', true),
      _DemoOption('c', 'Solo separa el borde superior.', false),
    ],
  ),
  _DemoQuestion(
    id: 'demo_w2_q4',
    worldId: 'world_2',
    topicId: 'flutter_stack',
    prompt: 'Que widget ubica un hijo dentro de un Stack por bordes?',
    type: 'single',
    explanation:
        'Positioned permite fijar distancias como top, right, bottom o left.',
    options: [
      _DemoOption('a', 'Positioned', true),
      _DemoOption('b', 'Padding', false),
      _DemoOption('c', 'Row', false),
    ],
  ),
];
