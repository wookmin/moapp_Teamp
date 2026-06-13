import 'package:flutter_test/flutter_test.dart';
import 'package:teamproject/models/nickname_status.dart';
import 'package:teamproject/repositories/firebase_profile_repository.dart';

void main() {
  group('nickname validation', () {
    test('accepts supported nickname characters', () {
      expect(FirebaseProfileRepository.validateNickname('장보고_7'), isNull);
    });

    test('rejects invalid length and characters', () {
      expect(FirebaseProfileRepository.validateNickname('가'), isNotNull);
      expect(FirebaseProfileRepository.validateNickname('장보고!'), isNotNull);
      expect(
        FirebaseProfileRepository.validateNickname('열두자를넘어가는닉네임입니다'),
        isNotNull,
      );
    });
  });

  test('nickname can be changed seven days after the last change', () {
    final now = DateTime.now();
    final locked = NicknameStatus(
      nickname: '장보고',
      changedAt: now.subtract(const Duration(days: 3)),
      nextChangeAt: now.add(const Duration(days: 4)),
    );
    final unlocked = NicknameStatus(
      nickname: '장보고',
      changedAt: now.subtract(const Duration(days: 8)),
      nextChangeAt: now.subtract(const Duration(days: 1)),
    );

    expect(locked.canChange, isFalse);
    expect(unlocked.canChange, isTrue);
    expect(const NicknameStatus().canChange, isTrue);
  });
}
