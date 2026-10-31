class SeedWorld {
  const SeedWorld({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.colorHex,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final String colorHex;
  final int sortOrder;
}

class SeedTopic {
  const SeedTopic({
    required this.id,
    required this.worldId,
    required this.title,
    required this.description,
    required this.sortOrder,
  });

  final String id;
  final String worldId;
  final String title;
  final String description;
  final int sortOrder;
}

class SeedOption {
  const SeedOption({
    required this.id,
    required this.label,
    required this.codeSnippet,
    required this.isCorrect,
  });

  final String id;
  final String label;
  final String codeSnippet;
  final bool isCorrect;
}

class SeedMission {
  const SeedMission({
    required this.id,
    required this.worldId,
    required this.topicId,
    required this.title,
    required this.description,
    required this.paragraphs,
    required this.instructions,
    required this.hint,
    required this.category,
    required this.codeTemplate,
    required this.targetPlaceholder,
    required this.previewType,
    required this.sortOrder,
    required this.options,
  });

  final String id;
  final String worldId;
  final String topicId;
  final String title;
  final String description;
  final List<String> paragraphs;
  final List<String> instructions;
  final String hint;
  final String category;
  final List<String> codeTemplate;
  final String targetPlaceholder;
  final String previewType;
  final int sortOrder;
  final List<SeedOption> options;
}

const seedWorlds = [
  SeedWorld(
    id: 'world_1',
    title: 'Mundo 1: Fundamentos de Dart',
    description: 'Tipos y variables, valores inmutables, funciones breves, listas tipadas y null safety.',
    iconKey: 'code',
    colorHex: '#38BDF8',
    sortOrder: 1,
  ),
  SeedWorld(
    id: 'world_2',
    title: 'Mundo 2: Layouts & Flexbox',
    description: 'Distribución horizontal y vertical, padding uniforme y superposición con Stack y Positioned.',
    iconKey: 'widgets',
    colorHex: '#A855F7',
    sortOrder: 2,
  ),
];

const seedTopics = [
  SeedTopic(
    id: 'dart_numeric_types',
    worldId: 'world_1',
    title: 'Tipos numéricos',
    description: 'Variables y números enteros en Dart.',
    sortOrder: 1,
  ),
  SeedTopic(
    id: 'dart_final',
    worldId: 'world_1',
    title: 'Valores inmutables',
    description: 'Referencias que no deben reasignarse.',
    sortOrder: 2,
  ),
  SeedTopic(
    id: 'dart_arrow_functions',
    worldId: 'world_1',
    title: 'Funciones flecha',
    description: 'Funciones breves de una sola expresión.',
    sortOrder: 3,
  ),
  SeedTopic(
    id: 'dart_typed_lists',
    worldId: 'world_1',
    title: 'Listas tipadas',
    description: 'Colecciones ordenadas con tipos explícitos.',
    sortOrder: 4,
  ),
  SeedTopic(
    id: 'dart_null_safety',
    worldId: 'world_1',
    title: 'Null safety',
    description: 'Ausencia de valor expresada en el sistema de tipos.',
    sortOrder: 5,
  ),
  SeedTopic(
    id: 'flutter_row',
    worldId: 'world_2',
    title: 'Distribución con Row',
    description: 'Alineación horizontal y espacio libre.',
    sortOrder: 1,
  ),
  SeedTopic(
    id: 'flutter_column',
    worldId: 'world_2',
    title: 'Distribución con Column',
    description: 'Alineación vertical en el eje principal.',
    sortOrder: 2,
  ),
  SeedTopic(
    id: 'flutter_padding',
    worldId: 'world_2',
    title: 'Espaciado interno',
    description: 'Padding uniforme y por borde.',
    sortOrder: 3,
  ),
  SeedTopic(
    id: 'flutter_stack',
    worldId: 'world_2',
    title: 'Superposición',
    description: 'Stack y Positioned para ubicar widgets.',
    sortOrder: 4,
  ),
];

const seedMissions = [
  SeedMission(
    id: 'w1_m1',
    worldId: 'world_1',
    topicId: 'dart_numeric_types',
    title: 'Misión 1 • Variables y Tipos Primitivos',
    description: 'Selecciona el tipo de dato adecuado para declarar la vida inicial (número entero) del personaje.',
    paragraphs: [
      'En Dart, el tipo define qué valores puede almacenar una variable y qué operaciones admite. Los números pueden ser enteros o incluir decimales.',
      'La vida del héroe vale 100, por lo que debe representarse como un número sin parte decimal.',
    ],
    instructions: [
      'Observa el valor asignado a vidaHeroe y la vista previa.',
      'Decide si 100 contiene una parte decimal.',
      'Compara las opciones y elige el tipo para números enteros.',
    ],
    hint: 'Compara un valor sin decimal con uno que sí tiene parte decimal.',
    category: 'dart_basics',
    codeTemplate: [
      '{{ type }} vidaHeroe = 100;',
      'print("Vida inicial: \$vidaHeroe HP");',
    ],
    targetPlaceholder: '{{ type }}',
    previewType: 'dart.variables',
    sortOrder: 1,
    options: [
      SeedOption(
        id: 'String',
        label: 'String',
        codeSnippet: 'String',
        isCorrect: false,
      ),
      SeedOption(id: 'int', label: 'int', codeSnippet: 'int', isCorrect: true),
      SeedOption(
        id: 'double',
        label: 'double',
        codeSnippet: 'double',
        isCorrect: false,
      ),
    ],
  ),
  SeedMission(
    id: 'w1_m2',
    worldId: 'world_1',
    topicId: 'dart_final',
    title: 'Misión 2 • Inmutabilidad con final',
    description: 'El nombre del héroe no debe cambiar durante la aventura. Usa la palabra clave para declarar una variable inmutable.',
    paragraphs: [
      'Dart permite proteger una variable contra nuevas asignaciones cuando su referencia debe permanecer estable. Esto no exige conocer el valor al compilar.',
      'El nombre del héroe recibe un valor inicial y no debe reemplazarse durante la aventura.',
    ],
    instructions: [
      'Observa cómo se inicializa la variable nombreHeroe.',
      'Identifica que su valor no debe cambiar después.',
      'Elige la declaración que impide una segunda asignación.',
    ],
    hint: 'La declaración debe impedir una segunda asignación sin exigir un valor de compilación.',
    category: 'dart_basics',
    codeTemplate: [
      '{{ keyword }} nombreHeroe = "Kael";',
      '// nombreHeroe = "Otro"; // Error en compilación',
    ],
    targetPlaceholder: '{{ keyword }}',
    previewType: 'dart.final',
    sortOrder: 2,
    options: [
      SeedOption(id: 'var', label: 'var', codeSnippet: 'var', isCorrect: false),
      SeedOption(
        id: 'final',
        label: 'final',
        codeSnippet: 'final',
        isCorrect: true,
      ),
      SeedOption(
        id: 'dynamic',
        label: 'dynamic',
        codeSnippet: 'dynamic',
        isCorrect: false,
      ),
    ],
  ),
  SeedMission(
    id: 'w1_m3',
    worldId: 'world_1',
    topicId: 'dart_arrow_functions',
    title: 'Misión 3 • Funciones Flecha (=>)',
    description: 'Completa la función de ataque especial simplificando su retorno con la sintaxis de flecha (=>).',
    paragraphs: [
      'Una función que retorna una sola expresión puede escribirse de forma abreviada. La expresión se evalúa y su resultado se devuelve automáticamente.',
      'El ataque especial solo necesita calcular y retornar el doble de la fuerza recibida.',
    ],
    instructions: [
      'Observa que la función solo calcula fuerza multiplicada por dos.',
      'Relaciona ese cálculo con el retorno de una sola expresión.',
      'Compara los operadores y elige la sintaxis abreviada.',
    ],
    hint: 'Busca la forma equivalente a un bloque que solo retorna una expresión.',
    category: 'dart_basics',
    codeTemplate: ['int calcularAtaque(int fuerza) {{ arrow }} fuerza * 2;'],
    targetPlaceholder: '{{ arrow }}',
    previewType: 'dart.arrow',
    sortOrder: 3,
    options: [
      SeedOption(id: 'arrow', label: '=>', codeSnippet: '=>', isCorrect: true),
      SeedOption(id: 'colon', label: ':', codeSnippet: ':', isCorrect: false),
      SeedOption(id: 'equal', label: '=', codeSnippet: '=', isCorrect: false),
    ],
  ),
  SeedMission(
    id: 'w1_m4',
    worldId: 'world_1',
    topicId: 'dart_typed_lists',
    title: 'Misión 4 • Inventario con Listas',
    description: 'Declara la lista genérica de objetos de tipo String para armar el inventario del héroe.',
    paragraphs: [
      'Una lista es una colección ordenada. Al declarar el tipo de sus elementos, el analizador puede detectar valores incompatibles.',
      'El inventario contiene varios elementos de texto y debe impedir que se agreguen objetos de otro tipo.',
    ],
    instructions: [
      'Observa los elementos incluidos en el inventario.',
      'Identifica que forman una colección ordenada de texto.',
      'Elige la colección tipada que solo acepte esos elementos.',
    ],
    hint: 'La colección debe conservar el orden y aceptar únicamente texto.',
    category: 'dart_basics',
    codeTemplate: [
      '{{ listType }} inventario = ["Espada", "Escudo", "Poción"];',
      'print("Items: \${inventario.length}");',
    ],
    targetPlaceholder: '{{ listType }}',
    previewType: 'dart.lists',
    sortOrder: 4,
    options: [
      SeedOption(
        id: 'List<String>',
        label: 'List<String>',
        codeSnippet: 'List<String>',
        isCorrect: true,
      ),
      SeedOption(
        id: 'Map<String>',
        label: 'Map<String>',
        codeSnippet: 'Map<String>',
        isCorrect: false,
      ),
      SeedOption(id: 'Set', label: 'Set', codeSnippet: 'Set', isCorrect: false),
    ],
  ),
  SeedMission(
    id: 'w1_m5',
    worldId: 'world_1',
    topicId: 'dart_null_safety',
    title: 'Misión 5 • Null Safety (?)',
    description: 'Un arma opcional puede ser nula si el héroe no tiene nada equipado. Marca el tipo de dato como anulable.',
    paragraphs: [
      'Los tipos de Dart no aceptan null de manera predeterminada. Cuando la ausencia de un valor es válida, la declaración debe expresarlo.',
      'El héroe puede tener un arma de texto o no tener ninguna, por lo que ambos estados deben ser válidos.',
    ],
    instructions: [
      'Observa que armaEquipada comienza con el valor null.',
      'Conserva el tipo de texto para cuando exista un arma.',
      'Elige la variante que permita valor y ausencia de valor.',
    ],
    hint: 'La declaración debe permitir tanto texto como ausencia de valor.',
    category: 'dart_basics',
    codeTemplate: [
      '{{ nullableType }} armaEquipada = null;',
      'print(armaEquipada ?? "Sin arma");',
    ],
    targetPlaceholder: '{{ nullableType }}',
    previewType: 'dart.null_safety',
    sortOrder: 5,
    options: [
      SeedOption(
        id: 'String?',
        label: 'String?',
        codeSnippet: 'String?',
        isCorrect: true,
      ),
      SeedOption(
        id: 'String!',
        label: 'String!',
        codeSnippet: 'String!',
        isCorrect: false,
      ),
      SeedOption(
        id: 'String',
        label: 'String',
        codeSnippet: 'String',
        isCorrect: false,
      ),
    ],
  ),
  SeedMission(
    id: 'w2_m1',
    worldId: 'world_2',
    topicId: 'flutter_row',
    title: 'Misión 1 • Distribución Horizontal (Row)',
    description: 'Ajusta la alineación del Row para colocar las 3 gemas dentro de los objetivos marcados.',
    paragraphs: [
      'Row organiza widgets horizontalmente. Su eje principal también es horizontal y la alineación determina cómo se reparte el espacio libre.',
      'Las tres gemas deben coincidir con objetivos ubicados en el inicio, centro y final del área disponible.',
    ],
    instructions: [
      'Compara las gemas con las tres siluetas objetivo.',
      'Observa que la primera y la última ocupan los extremos.',
      'Elige la distribución que deje espacio solo entre elementos.',
    ],
    hint: 'El espacio libre debe quedar entre las gemas, no alrededor de los extremos.',
    category: 'layout',
    codeTemplate: [
      'Row(',
      '  mainAxisAlignment: {{ alignment }},',
      '  children: [',
      '    GemaWidget(color: Colors.purple),',
      '    GemaWidget(color: Colors.cyan),',
      '    GemaWidget(color: Colors.green),',
      '  ],',
      ')',
    ],
    targetPlaceholder: '{{ alignment }}',
    previewType: 'flutter.row',
    sortOrder: 1,
    options: [
      SeedOption(
        id: 'center',
        label: 'MainAxisAlignment.center',
        codeSnippet: 'MainAxisAlignment.center',
        isCorrect: false,
      ),
      SeedOption(
        id: 'space_between',
        label: 'MainAxisAlignment.spaceBetween',
        codeSnippet: 'MainAxisAlignment.spaceBetween',
        isCorrect: true,
      ),
      SeedOption(
        id: 'end',
        label: 'MainAxisAlignment.end',
        codeSnippet: 'MainAxisAlignment.end',
        isCorrect: false,
      ),
    ],
  ),
  SeedMission(
    id: 'w2_m2',
    worldId: 'world_2',
    topicId: 'flutter_column',
    title: 'Misión 2 • Apilamiento Vertical (Column)',
    description: 'Mueve la plataforma de salto hacia la parte inferior para que encaje en la silueta objetivo.',
    paragraphs: [
      'Column organiza widgets verticalmente. Su eje principal va de arriba abajo y controla la posición vertical de sus hijos.',
      'La plataforma debe abandonar la parte superior y coincidir con el objetivo situado en el extremo inferior.',
    ],
    instructions: [
      'Observa la posición inicial y la silueta de destino.',
      'Relaciona la parte inferior con el final del eje vertical.',
      'Elige la alineación que lleve el hijo a ese extremo.',
    ],
    hint: 'En un eje vertical, el objetivo está en el extremo inferior.',
    category: 'layout',
    codeTemplate: [
      'Column(',
      '  mainAxisAlignment: {{ v_alignment }},',
      '  children: [',
      '    PlataformaWidget(),',
      '  ],',
      ')',
    ],
    targetPlaceholder: '{{ v_alignment }}',
    previewType: 'flutter.column',
    sortOrder: 2,
    options: [
      SeedOption(
        id: 'start',
        label: 'MainAxisAlignment.start',
        codeSnippet: 'MainAxisAlignment.start',
        isCorrect: false,
      ),
      SeedOption(
        id: 'center',
        label: 'MainAxisAlignment.center',
        codeSnippet: 'MainAxisAlignment.center',
        isCorrect: false,
      ),
      SeedOption(
        id: 'end',
        label: 'MainAxisAlignment.end',
        codeSnippet: 'MainAxisAlignment.end',
        isCorrect: true,
      ),
    ],
  ),
  SeedMission(
    id: 'w2_m3',
    worldId: 'world_2',
    topicId: 'flutter_padding',
    title: 'Misión 3 • Dimensiones y Padding',
    description: 'Aplica el espaciado interno correcto (Padding) para separar la gema del borde del contenedor.',
    paragraphs: [
      'El padding es el espacio interno entre un contenedor y su hijo. Puede aplicarse uniformemente o configurarse de forma independiente por borde.',
      'La gema necesita la misma separación interna de 32 píxeles en sus cuatro lados.',
    ],
    instructions: [
      'Observa la distancia entre la gema y cada borde.',
      'Descarta la ausencia de espacio y el ajuste de un solo lado.',
      'Elige una separación interna uniforme de 32 píxeles.',
    ],
    hint: 'La separación solicitada es interna, uniforme y de 32 píxeles.',
    category: 'layout',
    codeTemplate: [
      'Container(',
      '  padding: {{ padding }},',
      '  color: Colors.indigo,',
      '  child: GemaWidget(),',
      ')',
    ],
    targetPlaceholder: '{{ padding }}',
    previewType: 'flutter.padding',
    sortOrder: 3,
    options: [
      SeedOption(
        id: 'zero',
        label: 'EdgeInsets.zero',
        codeSnippet: 'EdgeInsets.zero',
        isCorrect: false,
      ),
      SeedOption(
        id: 'all_32',
        label: 'EdgeInsets.all(32.0)',
        codeSnippet: 'EdgeInsets.all(32.0)',
        isCorrect: true,
      ),
      SeedOption(
        id: 'only_top',
        label: 'EdgeInsets.only(top: 10)',
        codeSnippet: 'EdgeInsets.only(top: 10)',
        isCorrect: false,
      ),
    ],
  ),
  SeedMission(
    id: 'w2_m4',
    worldId: 'world_2',
    topicId: 'flutter_stack',
    title: 'Misión 4 • Superposición con Stack',
    description: 'Superpone el escudo protector exactamente en la esquina superior derecha del personaje usando Positioned.',
    paragraphs: [
      'Stack permite superponer widgets. Positioned ubica un hijo usando distancias desde los bordes del área apilada.',
      'El escudo debe superponerse al personaje tomando como referencia los bordes superior y derecho.',
    ],
    instructions: [
      'Localiza la silueta objetivo alrededor del personaje.',
      'Identifica los dos bordes que forman esa esquina.',
      'Elige los desplazamientos asociados con ambos bordes.',
    ],
    hint: 'La referencia combina los bordes superior y derecho del Stack.',
    category: 'layout',
    codeTemplate: [
      'Stack(',
      '  children: [',
      '    HeroeWidget(),',
      '    Positioned(',
      '      {{ positioning }},',
      '      child: Escudo(),',
      '    ),',
      '  ],',
      ')',
    ],
    targetPlaceholder: '{{ positioning }}',
    previewType: 'flutter.stack',
    sortOrder: 4,
    options: [
      SeedOption(
        id: 'top_right',
        label: 'top: 10, right: 10',
        codeSnippet: 'top: 10, right: 10',
        isCorrect: true,
      ),
      SeedOption(
        id: 'bottom_left',
        label: 'bottom: 10, left: 10',
        codeSnippet: 'bottom: 10, left: 10',
        isCorrect: false,
      ),
      SeedOption(
        id: 'center',
        label: 'top: 100, left: 100',
        codeSnippet: 'top: 100, left: 100',
        isCorrect: false,
      ),
    ],
  ),
];
