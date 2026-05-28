import 'package:firebase_auth/firebase_auth.dart';

import '../models/auth_user.dart';

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Stream<AuthUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = _mapUser(credential.user);
    if (user == null) {
      throw StateError('Firebase Auth did not return a user.');
    }

    return user;
  }

  Future<AuthUser> createUserWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = _mapUser(credential.user);
    if (user == null) {
      throw StateError('Firebase Auth did not return a user.');
    }

    return user;
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  AuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return AuthUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      isGuest: user.isAnonymous,
    );
  }
}
