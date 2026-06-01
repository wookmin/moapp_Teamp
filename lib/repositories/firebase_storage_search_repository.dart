import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/storage_tip.dart';
import 'storage_search_repository.dart';

class FirebaseStorageSearchRepository implements StorageSearchRepository {
  FirebaseStorageSearchRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<StorageTip>> searchStorageTips(String query) async {
    final normalizedQuery = _normalizeKeyword(query);
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final indexDoc = await _firestore
        .collection('ingredient_search_index')
        .doc(normalizedQuery)
        .get();
    final ingredientId = indexDoc.data()?['ingredientId'] as String?;
    if (ingredientId == null || ingredientId.isEmpty) {
      return const [];
    }

    final ingredientRef = _firestore.collection('ingredients').doc(ingredientId);

    // 병렬로 ingredient 문서, 보관 규칙, 출처를 동시에 조회
    final results = await Future.wait([
      ingredientRef.get(),
      ingredientRef
          .collection('storage_rules')
          .where('reviewStatus', isEqualTo: 'auto_approved')
          .get(),
      ingredientRef
          .collection('sources')
          .orderBy('priority', descending: true)
          .limit(1)
          .get(),
    ]);

    final ingredient = (results[0] as DocumentSnapshot).data() as Map<String, Object?>?;
    if (ingredient == null) return const [];

    final ruleSnapshot = results[1] as QuerySnapshot;
    final sourceSnapshot = results[2] as QuerySnapshot;
    final source = sourceSnapshot.docs.isEmpty
        ? null
        : sourceSnapshot.docs.first.data() as Map<String, Object?>?;

    return ruleSnapshot.docs.map((doc) {
      return StorageTip.fromFirestoreSearch(
        ingredient: ingredient,
        rule: doc.data() as Map<String, Object?>,
        source: source,
      );
    }).toList();
  }

  String _normalizeKeyword(String value) {
    return value.replaceAll(RegExp(r'\s'), '').trim().toLowerCase();
  }
}
