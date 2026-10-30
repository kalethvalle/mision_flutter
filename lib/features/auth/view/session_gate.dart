import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_model.dart';
import '../../../core/repositories/catalog_repository.dart';
import '../../../core/store/game_store.dart';
import '../../../core/store/session_store.dart';
import '../../home/view/home_screen.dart';
import 'teacher_dashboard.dart';

class SessionGate extends StatelessWidget {
  const SessionGate({super.key, required this.repository});

  final FlutterQuestRepository repository;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStore>();
    return switch (session.state) {
      SessionState.loading => const _SessionLoading(),
      SessionState.bootstrapRequired => const _CredentialsView(
        mode: _CredentialsMode.bootstrap,
      ),
      SessionState.signedOut => const _CredentialsView(
        mode: _CredentialsMode.login,
      ),
      SessionState.failure => _SessionFailure(message: session.error),
      SessionState.authenticated =>
        session.user?.role == UserRole.teacher
            ? const TeacherDashboard()
            : ChangeNotifierProvider(
                key: ValueKey(session.user!.id),
                create: (_) => GameStore(repository)..initialize(),
                child: const HomeScreen(),
              ),
    };
  }
}

enum _CredentialsMode { bootstrap, login }

class _CredentialsView extends StatefulWidget {
  const _CredentialsView({required this.mode});

  final _CredentialsMode mode;

  @override
  State<_CredentialsView> createState() => _CredentialsViewState();
}

class _CredentialsViewState extends State<_CredentialsView> {
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
    final bootstrap = widget.mode == _CredentialsMode.bootstrap;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.explore_rounded,
                        size: 52,
                        color: Color(0xFF38BDF8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        bootstrap ? 'Crear docente inicial' : 'Iniciar sesión',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bootstrap
                            ? 'Esta cuenta administrará los estudiantes locales.'
                            : 'Continúa tu progreso en Flutter Quest.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 24),
                      if (bootstrap) ...[
                        TextFormField(
                          controller: _displayName,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del docente',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _username,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Usuario',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Clave',
                          helperText: 'Mínimo 10 caracteres',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) => (value?.length ?? 0) < 10
                            ? 'Usa al menos 10 caracteres.'
                            : null,
                      ),
                      if (session.error != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          session.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: session.isSubmitting ? null : _submit,
                        icon: session.isSubmitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                bootstrap
                                    ? Icons.admin_panel_settings
                                    : Icons.login,
                              ),
                        label: Text(bootstrap ? 'CREAR DOCENTE' : 'INGRESAR'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Campo obligatorio.' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final session = context.read<SessionStore>();
    if (widget.mode == _CredentialsMode.bootstrap) {
      await session.bootstrapTeacher(
        username: _username.text,
        displayName: _displayName.text,
        password: _password.text,
      );
    } else {
      await session.login(username: _username.text, password: _password.text);
    }
  }
}

class _SessionLoading extends StatelessWidget {
  const _SessionLoading();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF0F172A),
    body: Center(child: CircularProgressIndicator()),
  );
}

class _SessionFailure extends StatelessWidget {
  const _SessionFailure({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF0F172A),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(message ?? 'No fue posible iniciar la aplicación.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: context.read<SessionStore>().initialize,
              child: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    ),
  );
}
