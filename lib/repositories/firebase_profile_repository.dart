import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/nickname_status.dart';
import '../models/profile_data.dart';
import '../services/freshness_calculator.dart';
import 'firebase_expiry_repository.dart';
import 'profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  static const nicknameChangeInterval = Duration(days: 7);

  FirebaseProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseExpiryRepository? expiryRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _expiryRepository =
           expiryRepository ??
           FirebaseExpiryRepository(firestore: firestore, auth: auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseExpiryRepository _expiryRepository;

  DocumentReference<Map<String, dynamic>> get _userDocument {
    final user = _auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');
    return _firestore.collection('users').doc(user.uid);
  }

  @override
  Future<ProfileData> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const ProfileData(name: '', subtitle: '', freshnessScore: 0);
    }

    final doc = await _userDocument.get();
    final data = doc.data() ?? {};

    final nickname = data['nickname'] as String?;
    final legacyName = data['name'] as String?;
    final name = nickname?.trim().isNotEmpty == true
        ? nickname!.trim()
        : legacyName?.trim().isNotEmpty == true
        ? legacyName!.trim()
        : user.email ?? '사용자';
    final subtitle = data['subtitle'] as String? ?? '냉장고 관리 중';
    final foods = await _expiryRepository.fetchExpiryItems();
    final freshnessScore = FreshnessCalculator.calculate(foods);

    return ProfileData(
      name: name,
      subtitle: subtitle,
      freshnessScore: freshnessScore,
      menuItems: const [
        ProfileMenuItem(title: '냉장고 관리', actionKey: 'expiry'),
        ProfileMenuItem(title: '쇼핑 추천', actionKey: 'shopping'),
        ProfileMenuItem(title: '저장된 팁', actionKey: 'saved_tips'),

        ProfileMenuItem(
          title: '로그아웃',
          actionKey: 'signOut',
          isDestructive: true,
        ),
      ],
    );
  }

  @override
  Future<NicknameStatus> fetchNicknameStatus() async {
    final snapshot = await _userDocument.get();
    final data = snapshot.data();
    final nickname = (data?['nickname'] as String?)?.trim();
    final changedAt = (data?['nicknameChangedAt'] as Timestamp?)?.toDate();

    return NicknameStatus(
      nickname: nickname,
      changedAt: changedAt,
      nextChangeAt: changedAt?.add(nicknameChangeInterval),
    );
  }

  @override
  Future<void> updateNickname(String nickname) async {
    final normalized = nickname.trim();
    final validationError = validateNickname(normalized);
    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    await _firestore.runTransaction((transaction) async {
      final reference = _userDocument;
      final snapshot = await transaction.get(reference);
      final data = snapshot.data();
      final currentNickname = (data?['nickname'] as String?)?.trim();
      final changedAt = (data?['nicknameChangedAt'] as Timestamp?)?.toDate();
      final nextChangeAt = changedAt?.add(nicknameChangeInterval);

      if (currentNickname == normalized) {
        throw StateError('현재 사용 중인 닉네임과 같아요.');
      }
      if (currentNickname?.isNotEmpty == true &&
          nextChangeAt != null &&
          DateTime.now().isBefore(nextChangeAt)) {
        throw StateError('${_formatDate(nextChangeAt)}부터 닉네임을 다시 변경할 수 있어요.');
      }

      transaction.set(reference, {
        'nickname': normalized,
        'name': normalized,
        'nicknameChangedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    await _auth.currentUser?.updateDisplayName(normalized);
  }

  static String? validateNickname(String value) {
    final nickname = value.trim();
    if (nickname.length < 2 || nickname.length > 12) {
      return '닉네임은 2자 이상 12자 이하로 입력해주세요.';
    }
    if (!RegExp(r'^[가-힣A-Za-z0-9_]+$').hasMatch(nickname)) {
      return '한글, 영문, 숫자, 밑줄만 사용할 수 있어요.';
    }
    return null;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}
