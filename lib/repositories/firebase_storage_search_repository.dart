import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/storage_tip.dart';
import 'storage_search_repository.dart';

class FirebaseStorageSearchRepository implements StorageSearchRepository {
  FirebaseStorageSearchRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<StorageTip>> searchStorageTips(String query) async {
    try {
      final normalizedQuery = _normalizeKeyword(query);
      if (normalizedQuery.isEmpty) {
        return const [];
      }

      final ingredientId = await _findIngredientId(normalizedQuery);
      if (ingredientId == null || ingredientId.isEmpty) {
        return const [];
      }

      final ingredientRef = _firestore
          .collection('ingredients')
          .doc(ingredientId);

      // 병렬로 ingredient 문서, 보관 규칙, 출처를 동시에 조회
      final results = await Future.wait([
        ingredientRef.get(),
        ingredientRef
            .collection('storage_rules')
            .where('reviewStatus', isEqualTo: 'auto_approved')
            .get(),
        ingredientRef.collection('sources').limit(1).get(),
      ]);

      final ingredient =
          (results[0] as DocumentSnapshot).data() as Map<String, Object?>?;
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
    } on FirebaseException catch (error) {
      throw Exception(_mapFirestoreError(error));
    }
  }

  Future<String?> _findIngredientId(String normalizedQuery) async {
    final indexDoc = await _firestore
        .collection('ingredient_search_index')
        .doc(normalizedQuery)
        .get();
    final exactIngredientId = indexDoc.data()?['ingredientId'] as String?;
    if (exactIngredientId != null && exactIngredientId.isNotEmpty) {
      return exactIngredientId;
    }

    final indexQuery = await _firestore
        .collection('ingredient_search_index')
        .where('normalizedKeyword', isEqualTo: normalizedQuery)
        .limit(1)
        .get();
    if (indexQuery.docs.isNotEmpty) {
      final ingredientId =
          indexQuery.docs.first.data()['ingredientId'] as String?;
      if (ingredientId != null && ingredientId.isNotEmpty) {
        return ingredientId;
      }
    }

    final ingredientByKeyword = await _firestore
        .collection('ingredients')
        .where('searchKeywords', arrayContains: normalizedQuery)
        .limit(1)
        .get();
    if (ingredientByKeyword.docs.isNotEmpty) {
      return ingredientByKeyword.docs.first.id;
    }

    final ingredientByName = await _firestore
        .collection('ingredients')
        .where('nameKo', isEqualTo: normalizedQuery)
        .limit(1)
        .get();
    if (ingredientByName.docs.isNotEmpty) {
      return ingredientByName.docs.first.id;
    }

    return null;
  }

  String _normalizeKeyword(String value) {
    return value.replaceAll(RegExp(r'\s'), '').trim().toLowerCase();
  }

  String _mapFirestoreError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Firestore 읽기 권한이 없습니다. ingredient_search_index와 ingredients 읽기 rules를 확인해주세요.';
    }
    if (error.code == 'unavailable') {
      return 'Firestore에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
    }
    return 'Firestore 검색 중 오류가 발생했습니다. (${error.code})';
  }
}
