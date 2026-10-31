import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_model.dart';
import '../../../core/store/session_store.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    final students = session.users
        .where((user) => user.role == UserRole.student)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Panel docente • ${session.user!.displayName}'),
        actions: [
          IconButton(
            onPressed: session.isSubmitting ? null : session.logout,
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 850;
          final form = _StudentForm(
            formKey: _formKey,
            username: _username,
            displayName: _displayName,
            password: _password,
            onSubmit: _createStudent,
          );
          final list = _StudentList(students: students);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: compact
                ? Column(children: [form, const SizedBox(height: 24), list])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: form),
                      const SizedBox(width: 24),
                      Expanded(flex: 6, child: list),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Future<void> _createStudent() async {
    if (!_formKey.currentState!.validate()) return;
    final created = await context.read<SessionStore>().createStudent(
      username: _username.text,
      displayName: _displayName.text,
      password: _password.text,
    );
    if (!created || !mounted) return;
    _username.clear();
    _displayName.clear();
    _password.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estudiante creado correctamente.')),
    );
  }
}

class _StudentForm extends StatelessWidget {
  const _StudentForm({
    required this.formKey,
    required this.username,
    required this.displayName,
    required this.password,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController username;
  final TextEditingController displayName;
  final TextEditingController password;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crear estudiante',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: displayName,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: username,
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Usuario'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Clave',
                  helperText: 'Mínimo 10 caracteres',
                ),
                validator: (value) => (value?.length ?? 0) < 10
                    ? 'Usa al menos 10 caracteres.'
                    : null,
              ),
              if (session.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  session.error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: session.isSubmitting ? null : onSubmit,
                icon: const Icon(Icons.person_add),
                label: const Text('CREAR ESTUDIANTE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;
  }
}

class _StudentList extends StatelessWidget {
  const _StudentList({required this.students});

  final List<UserModel> students;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF1E293B),
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Estudiantes (${students.length})',
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          if (students.isEmpty)
            const Text(
              'Aún no hay estudiantes registrados.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            )
          else
            ...students.map(
              (student) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.school)),
                title: Text(student.displayName),
                subtitle: Text('@${student.username}'),
              ),
            ),
        ],
      ),
    ),
  );
}
