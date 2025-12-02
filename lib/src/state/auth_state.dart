import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/user_repository.dart';
import '../models/user_profile.dart';

class AuthState extends ChangeNotifier {
  bool get firebaseReady => Firebase.apps.isNotEmpty;

  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get user => firebaseReady ? _auth.currentUser : null;

  bool get isLoggedIn => user != null;

  final _userRepo = UserRepository();
  UserProfile? _profile;
  UserProfile? get profile => _profile;

  Future<bool> _ensureReady() async {
    if (firebaseReady) return true;
    try {
      await Firebase.initializeApp();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    if (!await _ensureReady()) return;
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return; // cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.signInWithCredential(credential);
    // Provision user profile
    _profile = await _userRepo.ensureProfile();
    _userRepo.watchProfile().listen((p) {
      _profile = p;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> signOut() async {
    if (!firebaseReady) return;
    await _auth.signOut();
    _profile = null;
    notifyListeners();
  }
}