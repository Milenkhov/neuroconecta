import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'package:flutter/foundation.dart';

class UserRepository {
  final _users = FirebaseFirestore.instance.collection('users');
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<UserProfile?> fetchProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Stream<UserProfile?> watchProfile() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _users.doc(uid).snapshots().map((d) => d.exists ? UserProfile.fromDoc(d) : null);
  }

  Future<UserProfile> ensureProfile() async {
    final uid = _uid;
    if (uid == null) throw Exception('No user');
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      final profile = UserProfile(uid: uid, role: 'user', subscription: 'free', views: 0);
      await _users.doc(uid).set(profile.toMap());
      return profile;
    }
    return UserProfile.fromDoc(doc);
  }

  Future<void> incrementViewCount() async {
    final uid = _uid;
    if (uid == null) return;
    final doc = _users.doc(uid);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(doc);
        var views = 0;
        if (snap.exists) {
          views = (snap.data()?["views"] as num?)?.toInt() ?? 0;
        }
        tx.update(doc, {"views": views + 1});
      });
    } catch (e) {
      debugPrint('incrementViewCount failed: $e');
    }
  }

  Future<bool> canViewMore() async {
    final profile = await ensureProfile();
    if (profile.subscription == 'premium') return true;
    // Cuota gratuita: 2 visualizaciones
    return profile.views < 2;
  }

  Future<void> upgradeToPremium() async {
    final uid = _uid;
    if (uid == null) return;
    await _users.doc(uid).update({'subscription': 'premium'});
  }
}
