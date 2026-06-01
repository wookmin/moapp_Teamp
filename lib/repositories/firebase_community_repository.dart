import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community_post.dart';
import 'community_repository.dart';

class FirebaseCommunityRepository implements CommunityRepository {
  FirebaseCommunityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('posts');

  @override
  Future<List<CommunityPost>> fetchPosts({String filter = 'latest'}) async {
    final snapshot =
        await _collection.orderBy('createdAt', descending: true).limit(50).get();
    return snapshot.docs
        .map((doc) => CommunityPost.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> addPost(CommunityPost post) {
    return _collection.add(post.toFirestore());
  }
}
