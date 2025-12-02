import 'package:flutter/material.dart';
import '../src/routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action('Biblioteca', Icons.video_library, () => Navigator.pushNamed(context, Routes.library),
          subtitle: 'Explora cápsulas por categoría'),
      _Action('Formulario', Icons.edit, () => Navigator.pushNamed(context, Routes.form),
          subtitle: 'Crea o edita cápsulas'),
      _Action('Favoritos', Icons.star, () => Navigator.pushNamed(context, Routes.favorites),
          subtitle: 'Acceso rápido a tus guardados'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('NeuroConecta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const _HomeMascotGreeting(),
            const SizedBox(height: 16),
            ...List.generate(actions.length, (i) => _ActionBar(action: actions[i])),
          ].expand((w) sync* {
            yield w;
            yield const SizedBox(height: 12);
          }).toList()
            ..removeLast(),
        ),
      ),
    );
  }
}

class _Action {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  _Action(this.title, this.icon, this.onTap, {this.subtitle});
}

class _ActionBar extends StatelessWidget {
  final _Action action;
  const _ActionBar({required this.action});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: action.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
          ],
          gradient: LinearGradient(
            colors: [Colors.white, cs.primary.withValues(alpha: .04)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 22, backgroundColor: cs.primary.withValues(alpha: .15), child: Icon(action.icon, color: cs.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(action.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                if (action.subtitle != null)
                  Text(action.subtitle!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ]),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _HomeMascotGreeting extends StatelessWidget {
  const _HomeMascotGreeting();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cs.primary.withValues(alpha: .18),
            child: Icon(Icons.auto_awesome_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('¡Hola! ¿Listo para una cápsula?', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Explora, aprende y guarda tus favoritas.', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.favorite_rounded, color: Colors.pinkAccent),
        ],
      ),
    );
  }
}