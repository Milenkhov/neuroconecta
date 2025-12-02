import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import '../src/state/auth_state.dart';
import '../src/routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu espacio de bienestar')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            _LoginMascotBanner(color: cs.primary),
            const Spacer(),
            if (Firebase.apps.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Firebase no está configurado. Puedes seguir explorando,\npero el inicio de sesión y el CRUD requieren configuración.',
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Iniciar con Google'),
              onPressed: () async {
                await auth.signInWithGoogle();
                if (auth.isLoggedIn) {
                  final email = auth.user?.email ?? '';
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sesión iniciada con la cuenta: $email')),
                  );
                  // ignore: use_build_context_synchronously
                  Navigator.pushReplacementNamed(context, Routes.home);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginMascotBanner extends StatelessWidget {
  final Color color;
  const _LoginMascotBanner({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: .16),
            child: Icon(Icons.emoji_emotions_rounded, color: color, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bienvenido/a', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Inicia sesión para guardar favoritos, calificar y comentar.'),
              ],
            ),
          ),
          const Icon(Icons.key_rounded),
        ],
      ),
    );
  }
}