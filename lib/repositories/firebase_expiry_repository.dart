import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/food_item.dart';
import '../models/storage_type.dart';
import 'expiry_repository.dart';

class FirebaseExpiryRepository implements ExpiryRepository {
  FirebaseExpiryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    return _firestore.collection('users').doc(uid).collection('food_items');
  }

  @override
  Future<List<FoodItem>> fetchExpiryItems() async {
    final snapshot = await _collection.orderBy('expiryDate').get();
    return snapshot.docs
        .map((doc) => FoodItem.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Stream<List<FoodItem>> watchExpiryItems() {
    return _collection.orderBy('expiryDate').snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => FoodItem.fromFirestore(doc.id, doc.data()))
          .toList(),
    );
  }

  @override
  Future<void> addFoodItem({
    required String name,
    required DateTime expiryDate,
    String? category,
    StorageType storageType = StorageType.unknown,
  }) {
    return _collection.add({
      'name': name,
      'expiryDate': expiryDate.toIso8601String(),
      'category': category,
      'storageType': storageType.name,
    });
  }

  @override
  Future<void> deleteFoodItem(String id) {
    return _collection.doc(id).delete();
  }
}
