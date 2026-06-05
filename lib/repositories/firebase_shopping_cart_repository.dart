import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/shopping_cart_item.dart';
import '../models/shopping_recommendation.dart';
import 'shopping_cart_repository.dart';

class FirebaseShoppingCartRepository implements ShoppingCartRepository {
  FirebaseShoppingCartRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('shopping_cart_items');
  }

  @override
  Future<List<ShoppingCartItem>> fetchCartItems() async {
    final snapshot = await _collection.orderBy('createdAt').get();
    return snapshot.docs
        .map((doc) => ShoppingCartItem.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<bool> addCartItemFromRecommendation(ShoppingRecommendation item) async {
    final normalizedName = ShoppingCartItem.normalizeName(item.name);
    final duplicate = await _collection
        .where('nameLowercase', isEqualTo: normalizedName)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      return false;
    }

    final cartItem = ShoppingCartItem(
      id: '',
      name: item.name,
      note: item.note,
      tag: item.tag,
      isChecked: false,
      createdAt: DateTime.now(),
    );

    await _collection.add(cartItem.toFirestore());
    return true;
  }

  @override
  Future<int> addManyFromRecommendations(
    List<ShoppingRecommendation> items,
  ) async {
    var addedCount = 0;
    for (final item in items) {
      final added = await addCartItemFromRecommendation(item);
      if (added) {
        addedCount += 1;
      }
    }
    return addedCount;
  }

  @override
  Future<void> toggleChecked(String id, bool isChecked) {
    return _collection.doc(id).update({'isChecked': isChecked});
  }

  @override
  Future<void> deleteCartItem(String id) {
    return _collection.doc(id).delete();
  }
}
