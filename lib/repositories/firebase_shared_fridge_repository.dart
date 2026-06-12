import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_item.dart';
import '../models/shared_fridge.dart';
import '../models/storage_type.dart';
import 'shared_fridge_repository.dart';

class FirebaseSharedFridgeRepository implements SharedFridgeRepository {
  FirebaseSharedFridgeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    return uid;
  }

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _memberships =>
      _user(_uid).collection('fridge_access');

  @override
  Future<List<SharedFridge>> fetchMySharedFridges() async {
    final snapshot = await _memberships.orderBy('createdAt').get();
    final fridges = snapshot.docs
        .map((doc) => SharedFridge.fromMembership(doc.id, doc.data()))
        .where(
          (fridge) =>
              fridge.ownerUid.isNotEmpty &&
              fridge.ownerUid != _uid &&
              fridge.role != 'owner',
        )
        .toList();
    fridges.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return fridges;
  }

  @override
  Future<SharedFridgeInvite> createInvite({required String role}) async {
    if (role != 'viewer' && role != 'editor') {
      throw ArgumentError.value(role, 'role', '지원하지 않는 권한입니다.');
    }

    final ownerUid = _uid;
    final owner = _auth.currentUser!;
    final profile = await _user(ownerUid).get();
    final profileName = profile.data()?['name'] as String?;
    final ownerName = profileName?.trim().isNotEmpty == true
        ? profileName!.trim()
        : owner.displayName?.trim().isNotEmpty == true
        ? owner.displayName!.trim()
        : owner.email?.split('@').first ?? '친구';
    final fridgeName = '$ownerName님의 냉장고';
    final code = _generateCode();
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    await _user(ownerUid).collection('fridge_invites').doc(code).set({
      'ownerUid': ownerUid,
      'fridgeName': fridgeName,
      'createdBy': ownerUid,
      'role': role,
      'active': true,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return SharedFridgeInvite(
      ownerUid: ownerUid,
      code: code,
      fridgeName: fridgeName,
      role: role,
      expiresAt: expiresAt,
    );
  }

  @override
  Future<SharedFridgeInvite> fetchInvite({
    required String ownerUid,
    required String code,
  }) async {
    final snapshot = await _user(
      ownerUid,
    ).collection('fridge_invites').doc(code).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null || data['active'] != true) {
      throw StateError('사용할 수 없는 초대 링크입니다.');
    }

    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
      throw StateError('초대 링크가 만료되었습니다.');
    }

    return SharedFridgeInvite(
      ownerUid: ownerUid,
      code: code,
      fridgeName: data['fridgeName'] as String? ?? '친구의 냉장고',
      role: data['role'] as String? ?? 'viewer',
      expiresAt: expiresAt,
    );
  }

  @override
  Future<SharedFridge> acceptInvite({
    required String ownerUid,
    required String code,
  }) async {
    if (ownerUid == _uid) {
      throw StateError('내 냉장고 초대 링크에는 참여할 수 없습니다.');
    }

    final existingMembership = await _memberships.doc(ownerUid).get();
    final existingData = existingMembership.data();
    if (existingMembership.exists && existingData != null) {
      return SharedFridge.fromMembership(ownerUid, existingData);
    }

    final invite = await fetchInvite(ownerUid: ownerUid, code: code);
    final joinedAt = DateTime.now();
    final batch = _firestore.batch();

    batch.set(_user(ownerUid).collection('fridge_members').doc(_uid), {
      'role': invite.role,
      'inviteCode': code,
      'joinedAt': joinedAt.toIso8601String(),
    });
    batch.set(_memberships.doc(ownerUid), {
      'name': invite.fridgeName,
      'ownerUid': ownerUid,
      'role': invite.role,
      'inviteCode': code,
      'createdAt': joinedAt.toIso8601String(),
    });
    await batch.commit();

    return SharedFridge(
      id: ownerUid,
      name: invite.fridgeName,
      ownerUid: ownerUid,
      role: invite.role,
      createdAt: joinedAt,
    );
  }

  @override
  Future<List<FoodItem>> fetchFoodItems(String ownerUid) async {
    final snapshot = await _user(
      ownerUid,
    ).collection('food_items').orderBy('expiryDate').get();
    return snapshot.docs
        .map((doc) => FoodItem.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> addFoodItem({
    required String ownerUid,
    required String name,
    required DateTime expiryDate,
    StorageType storageType = StorageType.unknown,
  }) {
    return _user(ownerUid).collection('food_items').add({
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
      'storageType': storageType.name,
    });
  }

  String _generateCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      20,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
