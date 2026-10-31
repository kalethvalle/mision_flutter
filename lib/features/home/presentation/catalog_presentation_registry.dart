import 'package:flutter/material.dart';

typedef MissionPreviewBuilder = Widget Function(
  BuildContext context,
  String selectedOptionId,
);

class CatalogPresentationRegistry {
  const CatalogPresentationRegistry._();

  static IconData worldIcon(String iconKey) => switch (iconKey) {
    'code' => Icons.code_rounded,
    'widgets' => Icons.widgets_rounded,
    _ => Icons.public_rounded,
  };

  static Color worldColor(String colorHex) {
    final normalized = colorHex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null || normalized.length != 6) {
      return const Color(0xFF64748B);
    }
    return Color(0xFF000000 | value);
  }

  static Widget missionPreview(
    String previewType,
    BuildContext context,
    String optionId,
  ) {
    final builder = _previewBuilders[previewType];
    if (builder == null) {
      return const Center(
        child: Text(
          'Vista previa no compatible',
          style: TextStyle(color: Colors.redAccent),
        ),
      );
    }
    return builder(context, optionId);
  }

  static final Map<String, MissionPreviewBuilder> _previewBuilders = {
    'dart.variables': (_, optionId) {
      final correct = optionId == 'int';
      return _StatusPreview(
        icon: Icons.favorite_rounded,
        active: correct,
        successText: 'Vida: 100 HP',
        idleText: optionId.isEmpty ? 'Selecciona un tipo' : 'Tipo incorrecto',
      );
    },
    'dart.final': (_, optionId) {
      final correct = optionId == 'final';
      return _StatusPreview(
        icon: correct ? Icons.verified_user_rounded : Icons.shield_outlined,
        active: correct,
        successText: 'Héroe: Kael (Inmutable)',
        idleText: optionId.isEmpty
            ? 'Selecciona una declaración'
            : 'Variable mutable',
      );
    },
    'dart.arrow': (_, optionId) {
      final correct = optionId == 'arrow';
      return _StatusPreview(
        icon: Icons.flash_on_rounded,
        active: correct,
        successText: 'Ataque Especial: 50 de Daño',
        idleText: optionId.isEmpty
            ? 'Selecciona un operador'
            : 'Sintaxis inválida',
      );
    },
    'dart.lists': (_, optionId) {
      final correct = optionId == 'List<String>';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final item in const [
                  (Icons.shield, Colors.cyanAccent),
                  (Icons.colorize, Colors.redAccent),
                  (Icons.security, Colors.amberAccent),
                ]) ...[
                  Icon(
                    item.$1,
                    color: correct ? item.$2 : Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              correct
                  ? 'Inventario: 3 Objetos equipados'
                  : 'Selecciona una colección',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    },
    'dart.null_safety': (_, optionId) {
      final correct = optionId == 'String?';
      return _StatusPreview(
        icon: correct ? Icons.check_circle_outline : Icons.block_rounded,
        active: correct,
        successText: 'Estado: Sin arma (Seguro contra Null)',
        idleText: optionId.isEmpty
            ? 'Selecciona un tipo'
            : 'Error: No acepta null',
      );
    },
    'flutter.row': (_, optionId) {
      final alignment = switch (optionId) {
        'center' => MainAxisAlignment.center,
        'space_between' => MainAxisAlignment.spaceBetween,
        'end' => MainAxisAlignment.end,
        _ => MainAxisAlignment.start,
      };
      return Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(3, (_) => const _GemTarget()),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: alignment,
                children: const [
                  _Gem(color: Colors.purpleAccent),
                  _Gem(color: Colors.cyanAccent),
                  _Gem(color: Colors.greenAccent),
                ],
              ),
            ),
          ),
        ],
      );
    },
    'flutter.column': (_, optionId) {
      final alignment = switch (optionId) {
        'center' => MainAxisAlignment.center,
        'end' => MainAxisAlignment.end,
        _ => MainAxisAlignment.start,
      };
      return Stack(
        children: [
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(child: _platform(target: true)),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisAlignment: alignment,
                children: [_platform(target: false)],
              ),
            ),
          ),
        ],
      );
    },
    'flutter.padding': (_, optionId) {
      final padding = switch (optionId) {
        'all_32' => const EdgeInsets.all(32),
        'only_top' => const EdgeInsets.only(top: 10),
        _ => EdgeInsets.zero,
      };
      return Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            border: Border.all(color: const Color(0xFF3B82F6), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, color: Colors.black),
          ),
        ),
      );
    },
    'flutter.stack': (_, optionId) {
      final position = switch (optionId) {
        'top_right' => (top: 10.0, right: 10.0, bottom: null, left: null),
        'bottom_left' => (top: null, right: null, bottom: 10.0, left: 10.0),
        'center' => (top: 70.0, right: null, bottom: null, left: 70.0),
        _ => (top: null, right: null, bottom: null, left: null),
      };
      return Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Icon(
                  Icons.person,
                  size: 80,
                  color: Colors.white70,
                ),
              ),
              if (optionId.isNotEmpty)
                Positioned(
                  top: position.top,
                  right: position.right,
                  bottom: position.bottom,
                  left: position.left,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security,
                      color: Colors.black,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  };

  static Widget _platform({required bool target}) {
    return Container(
      width: 140,
      height: 48,
      decoration: BoxDecoration(
        color: target ? null : Colors.lightBlueAccent,
        border: target
            ? Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 2)
            : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: target
            ? const Icon(Icons.star_border_rounded, color: Colors.amber)
            : const Text(
                'PLATAFORMA',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

class _StatusPreview extends StatelessWidget {
  const _StatusPreview({
    required this.icon,
    required this.active,
    required this.successText,
    required this.idleText,
  });

  final IconData icon;
  final bool active;
  final String successText;
  final String idleText;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF38BDF8) : Colors.grey;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 64),
          const SizedBox(height: 16),
          Text(
            active ? successText : idleText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: active ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _GemTarget extends StatelessWidget {
  const _GemTarget();

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 2),
    ),
    child: const Icon(Icons.star_border_rounded, color: Colors.amber),
  );
}

class _Gem extends StatelessWidget {
  const _Gem({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.5),
          blurRadius: 12,
          spreadRadius: 2,
        ),
      ],
    ),
    child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 32),
  );
}
