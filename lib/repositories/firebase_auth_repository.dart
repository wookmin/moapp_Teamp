import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_user.dart';
import '../services/firebase_auth_service.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuthService? authService,
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _authService = authService ?? FirebaseAuthService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuthService _authService;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  @override
  Future<AuthUser> createUserWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _authService.createUserWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google 로그인이 취소되었습니다.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) throw StateError('Firebase Auth did not return a user.');
      return AuthUser(
        id: user.uid,
        email: user.email,
        displayName: user.displayName,
        isGuest: false,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code));
    }
  }

  @override
  Future<AuthUser> signInWithApple() {
    throw Exception('Apple 로그인은 준비 중입니다.');
  }

  @override
  Future<AuthUser> signInWithKakao() {
    throw Exception('카카오 로그인은 준비 중입니다.');
  }

  @override
  Future<AuthUser> continueAsGuest() {
    throw Exception('게스트 로그인은 준비 중입니다.');
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _authService.signOut();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호를 확인해주세요.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다.';
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      case 'too-many-requests':
        return '잠시 후 다시 시도해주세요.';
      default:
        return '오류가 발생했습니다. 다시 시도해주세요.';
    }
  }
}
