import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDataSource {
  FirebaseDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<Map<String, Object?>>> fetchCollection(
    String collectionPath,
  ) async {
    final snapshot = await _firestore.collection(collectionPath).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> setDocument({
    required String collectionPath,
    required String documentId,
    required Map<String, Object?> data,
  }) {
    return _firestore.collection(collectionPath).doc(documentId).set(data);
  }
}
