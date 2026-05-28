import '../../models/auth_user.dart';
import '../auth_repository.dart';

class PlaceholderAuthRepository implements AuthRepository {
  const PlaceholderAuthRepository();

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return AuthUser(id: 'placeholder-email-user', email: email);
  }

  @override
  Future<AuthUser> createUserWithEmail({
    required String email,
    required String password,
  }) async {
    return AuthUser(id: 'placeholder-email-user', email: email);
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    return const AuthUser(id: 'placeholder-google-user');
  }

  @override
  Future<AuthUser> signInWithApple() async {
    return const AuthUser(id: 'placeholder-apple-user');
  }

  @override
  Future<AuthUser> signInWithKakao() async {
    return const AuthUser(id: 'placeholder-kakao-user');
  }

  @override
  Future<AuthUser> continueAsGuest() async {
    return const AuthUser(id: 'guest-user', isGuest: true);
  }

  @override
  Future<void> signOut() async {}
}
