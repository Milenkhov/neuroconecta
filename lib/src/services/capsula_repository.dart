import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/capsula.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CapsulaRepository {
  final _capsulas = FirebaseFirestore.instance.collection('capsulas');
  final _favorites = FirebaseFirestore.instance.collection('favorites'); // doc id: userId_capsulaId
  final _ratings = FirebaseFirestore.instance.collection('ratings'); // fields: userId, capsulaId, stars
  final _comments = FirebaseFirestore.instance.collection('comments');

  Stream<List<Capsula>> watchAll() => _capsulas.orderBy('createdAt', descending: true).snapshots().map(
        (snap) => snap.docs.map(Capsula.fromDoc).toList(),
      );

  Stream<List<Capsula>> watchByCategory(String category) => _capsulas
      .where('category', isEqualTo: category)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Capsula.fromDoc).toList());

  Future<List<Capsula>> search(String text) async {
    final raw = text.trim();
    if (raw.isEmpty) return [];
    final tokens = _tokenize(raw);
    // Server-side first try using the first token for quick match
    final first = tokens.first;
    final query = await _capsulas.where('keywords', arrayContains: first).get();
    var results = query.docs.map(Capsula.fromDoc).toList();
    // Client-side refine to ensure all tokens are present
    results = results
        .where((c) {
          final keys = _keywordsFor(c).toSet();
          return tokens.every(keys.contains);
        })
        .toList();
    return results;
  }

  Future<void> create(Capsula c) async {
    await _capsulas.add({
      ...c.toMap(),
      'keywords': _keywordsFor(c),
    });
  }

  Future<void> update(Capsula c) async {
    await _capsulas.doc(c.id).update({
      ...c.toMap(),
      'keywords': _keywordsFor(c),
    });
  }

  Future<void> delete(String id) async => _capsulas.doc(id).delete();

  List<String> _keywordsFor(Capsula c) => _tokenize('${c.title} ${c.category} ${c.description}');

  List<String> _tokenize(String text) {
    final lower = text.toLowerCase();
    final normalized = lower
        .normalizeDiacritics(); // extension added below to remove accents for better search
    return normalized.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toSet().toList();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> backfillKeywords() async {
    try {
      final snap = await _capsulas.get();
      for (final d in snap.docs) {
        final c = Capsula.fromDoc(d);
        final keys = _keywordsFor(c);
        await d.reference.update({'keywords': keys});
      }
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('Backfill keywords failed: ${e.code} ${e.message}');
      } else {
        debugPrint('Backfill keywords failed: $e');
      }
    }
  }

  Future<void> backfillVideos() async {
    // Assign a default functional YouTube URL to any capsule missing videoUrl
    const fallbackYoutube = 'https://www.youtube.com/watch?v=XGSy3_Czz8k';
    try {
      final snap = await _capsulas.get();
      for (final d in snap.docs) {
        final data = d.data();
        final video = data['videoUrl'];
        if (video == null || (video is String && video.trim().isEmpty)) {
          await d.reference.update({'videoUrl': fallbackYoutube});
          continue;
        }
        if (video is String) {
          final u = Uri.tryParse(video);
          if (u == null || u.host.contains('example.com')) {
            await d.reference.update({'videoUrl': fallbackYoutube});
          }
        }
      }
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('Backfill videos failed: ${e.code} ${e.message}');
      } else {
        debugPrint('Backfill videos failed: $e');
      }
    }
  }

  Future<void> cleanupTestComments() async {
    try {
      final q = await _comments.where('text', isEqualTo: 'test').get();
      for (final d in q.docs) {
        await d.reference.delete();
      }
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('Cleanup comments failed: ${e.code}');
      }
    }
  }

  Stream<Set<String>> watchFavorites() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _favorites.where('userId', isEqualTo: uid).snapshots().map(
          (snap) => snap.docs.map((d) => d['capsulaId'] as String).toSet(),
        );
  }

  Future<void> toggleFavorite(String capsulaId) async {
    final uid = _uid;
    if (uid == null) return;
    final docId = '${uid}_$capsulaId';
    final doc = _favorites.doc(docId);
    try {
      final existing = await doc.get();
      if (existing.exists) {
        await doc.delete();
      } else {
        await doc.set({'userId': uid, 'capsulaId': capsulaId, 'createdAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      // Firestore may be disabled or unavailable; fail silently so UI does not crash.
      if (e is FirebaseException) {
        debugPrint('Favorite toggle failed: ${e.code} ${e.message}');
      } else {
        debugPrint('Favorite toggle failed: $e');
      }
    }
  }

  Stream<double> watchRatingAverage(String capsulaId) => _ratings
      .where('capsulaId', isEqualTo: capsulaId)
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) return 0.0;
        final total = snap.docs.map((d) => (d['stars'] as num?)?.toDouble() ?? 0.0).fold<double>(0.0, (a, b) => a + b);
        return total / snap.docs.length;
      });

  Stream<int> watchUserRating(String capsulaId) {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _ratings
        .where('capsulaId', isEqualTo: capsulaId)
        .where('userId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return 0;
          return (snap.docs.first['stars'] as num?)?.toInt() ?? 0;
        });
  }

  Future<void> setRating(String capsulaId, int stars) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final q = await _ratings.where('capsulaId', isEqualTo: capsulaId).where('userId', isEqualTo: uid).limit(1).get();
      if (q.docs.isEmpty) {
        await _ratings.add({
          'capsulaId': capsulaId,
          'userId': uid,
          'stars': stars,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await q.docs.first.reference.update({'stars': stars});
      }
    } catch (e) {
      if (e is FirebaseException) {
        debugPrint('Set rating failed: ${e.code} ${e.message}');
      } else {
        debugPrint('Set rating failed: $e');
      }
    }
  }
}

extension _Diacritics on String {
  String normalizeDiacritics() {
    const withDia = 'áàäâãåÁÀÄÂÃÅéèëêÉÈËÊíìïîÍÌÏÎóòöôõÓÒÖÔÕúùüûÚÙÜÛñÑçÇ';
    const noDia =   'aaaaaaAAAAAAeeeeEEEEiiiiIIIIoooooOOOOOuuuuUUUUnNcC';
    var out = this;
    for (var i = 0; i < withDia.length; i++) {
      out = out.replaceAll(withDia[i], noDia[i]);
    }
    return out;
  }
}
