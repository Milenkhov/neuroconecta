import 'package:flutter/material.dart';
import '../src/routes.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary.withValues(alpha: .08), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Mascot hero
                const SizedBox(height: 8),
                _HeroMascot(color: cs.primary),
                const SizedBox(height: 16),
                Text('NeuroConecta', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  'Herramientas breves para bienestar y aprendizaje.\nRespira, enfócate y crece cada día.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => Navigator.pushNamed(context, Routes.login),
                  label: const Text('Comenzar'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroMascot extends StatelessWidget {
  final Color color;
  const _HeroMascot({required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 30,
            child: _Bubble(radius: 28, color: color.withValues(alpha: .10)),
          ),
          Positioned(
            right: 24,
            top: 12,
            child: _Bubble(radius: 18, color: color.withValues(alpha: .12)),
          ),
          Positioned(
            bottom: 8,
            right: 48,
            child: _Bubble(radius: 14, color: color.withValues(alpha: .08)),
          ),
          CircleAvatar(
            radius: 56,
            backgroundColor: color.withValues(alpha: .16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology_alt_rounded, size: 38, color: color),
                const SizedBox(width: 6),
                Icon(Icons.favorite_rounded, size: 26, color: Colors.pinkAccent.withValues(alpha: .9)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double radius;
  final Color color;
  const _Bubble({required this.radius, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}