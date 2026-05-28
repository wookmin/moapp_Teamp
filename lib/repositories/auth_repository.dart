import '../models/auth_user.dart';

abstract class AuthRepository {
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> createUserWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signInWithGoogle();

  Future<AuthUser> signInWithApple();

  Future<AuthUser> signInWithKakao();

  Future<AuthUser> continueAsGuest();

  Future<void> signOut();
}
