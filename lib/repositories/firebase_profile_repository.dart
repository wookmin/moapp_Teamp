import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/profile_data.dart';
import '../services/freshness_calculator.dart';
import 'firebase_expiry_repository.dart';
import 'profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
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

  @override
  Future<ProfileData> fetchProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const ProfileData(name: '', subtitle: '', freshnessScore: 0);
    }

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};

    final name = (data['name'] as String?)?.isNotEmpty == true
        ? data['name'] as String
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
}
