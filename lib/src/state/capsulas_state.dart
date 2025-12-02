import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/capsula.dart';
import '../services/capsula_repository.dart';

class CapsulasState extends ChangeNotifier {
  final CapsulaRepository repo;
  CapsulasState(this.repo) {
    // Watch all capsules always
    _sub = repo.watchAll().listen((value) {
      _all = value;
      notifyListeners();
      _maybeSeed();
      // Ensure existing docs have searchable keywords
      // Fire-and-forget; errors are logged in repository
      unawaited(repo.backfillKeywords());
      // Ensure all documents have playable videos for demo/testing
      unawaited(repo.backfillVideos());
      // Remove placeholder comments like 'test'
      unawaited(repo.cleanupTestComments());
    });
    // Re-subscribe favorites whenever auth state changes so user login later works
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) => _subscribeFavorites());
    _subscribeFavorites();
  }

  List<Capsula> _all = [];
  Set<String> _favorites = {};
  StreamSubscription? _sub;
  StreamSubscription? _favSub;
  StreamSubscription? _authSub;
  bool _seedAttempted = false;

  List<Capsula> get all => _all;
  Set<String> get favorites => _favorites;

  Future<List<Capsula>> search(String text) => repo.search(text);

  bool isFavorite(String id) => _favorites.contains(id);
  Future<void> toggleFavorite(String id) => repo.toggleFavorite(id);

  Future<void> _maybeSeed() async {
    if (_seedAttempted) return;
    _seedAttempted = true;
    // Purge duplicates (same normalized title+category) leaving oldest
    if (_all.isNotEmpty) {
      final seen = <String, String>{}; // key -> id kept
      final toDelete = <String>[];
      for (final c in _all) {
        final key = '${c.title.toLowerCase().trim()}|${c.category.toLowerCase().trim()}';
        if (!seen.containsKey(key)) {
          seen[key] = c.id;
        } else {
          toDelete.add(c.id);
        }
      }
      for (final id in toDelete) {
        await repo.delete(id);
      }
    }
    // After purge, if collection still small (<8) seed diverse samples
    if (_all.length < 8) {
      final samples = [
        Capsula(
          id: '_',
          title: 'Respiración consciente básica',
          category: 'Mindfulness',
          description: 'Guiado de respiración diafragmática de 5 minutos para centrar la atención.',
          videoUrl: 'https://example.com/videos/respiracion.mp4',
          attachments: ['Guia_Respiracion.pdf'],
        ),
        Capsula(
          id: '_',
          title: 'Sílabas directas con pictogramas',
          category: 'Educación',
          description: 'Refuerzo de sílabas directas mediante asociación visual y repetición breve.',
          videoUrl: 'https://example.com/videos/lectoescritura.mp4',
          attachments: ['Fichas_Silabas.pdf'],
        ),
        Capsula(
          id: '_',
          title: 'Técnica de respiración 4-7-8',
          category: 'Salud',
          description: 'Uso de patrón 4-7-8 para inducir relajación fisiológica rápida.',
          videoUrl: 'https://example.com/videos/estres_478.mp4',
          attachments: ['Recordatorio_478.png'],
        ),
        Capsula(
          id: '_',
          title: 'Rutina de estiramientos cervicales',
          category: 'Fisioterapia',
          description: 'Secuencia corta para aliviar tensión en cuello y hombros tras estudio prolongado.',
          videoUrl: 'https://example.com/videos/estiramientos_cervicales.mp4',
          attachments: ['Rutina_Cervicales.pdf'],
        ),
        Capsula(
          id: '_',
          title: 'Visualización positiva matutina',
          category: 'Mindfulness',
          description: 'Ejercicio de 3 minutos para orientar el día con intención y calma.',
          videoUrl: 'https://example.com/videos/visualizacion_matutina.mp4',
          attachments: ['Guia_Visualizacion.pdf'],
        ),
        Capsula(
          id: '_',
          title: 'Apoyo dislexia: patrones de color',
          category: 'Educación',
          description: 'Uso de codificación por color para facilitar segmentación de palabras complejas.',
          attachments: ['Plantilla_Patrones_Color.pdf'],
        ),
        Capsula(
          id: '_',
          title: 'Higiene del sueño: checklist nocturna',
          category: 'Salud',
          description: 'Lista de verificación breve para hábitos previos al descanso reparador.',
          attachments: ['Checklist_Sueno.pdf'],
        ),
        Capsula(
          id: '_',
          title: 'Respiración cuadrada para foco',
          category: 'Mindfulness',
          description: 'Inhalar-retener-exhalar-retener en partes iguales para estabilizar atención.',
          attachments: ['Guia_Cuadrada.png'],
        ),
        Capsula(
          id: '_',
          title: 'Ejercicio cognitivo: memoria de trabajo 5x5',
          category: 'Neurocognitivo',
          description: 'Secuencia de dígitos/pictos que incrementa dificultad para entrenar memoria de trabajo.',
          attachments: ['Plantilla_5x5.pdf'],
        ),
        Capsula(
          id: '_',
          title: 'Técnica Pomodoro adaptada',
          category: 'Productividad',
          description: 'Intervalos de 20/5 con micro-movimientos para mantener regulación atencional.',
          attachments: ['Timer_Pomodoro.png'],
        ),
        Capsula(
          id: '_',
          title: 'Autoevaluación emocional breve',
          category: 'Regulación Emocional',
          description: 'Escala rápida de 5 ítems para identificar estado y elegir intervención.',
          attachments: ['Escala_Emocional.pdf'],
        ),
      ];
      for (final s in samples) {
        await repo.create(s);
      }
    }
  }

  void _subscribeFavorites() {
    _favSub?.cancel();
    _favSub = repo.watchFavorites().listen((ids) {
      _favorites = ids;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _favSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
