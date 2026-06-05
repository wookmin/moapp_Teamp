import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community_comment.dart';
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
    final snapshot = await _collection
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs
        .map((doc) => CommunityPost.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> addPost(CommunityPost post) {
    return _collection.add(post.toFirestore());
  }

  @override
  Future<List<CommunityComment>> fetchComments(String postId) async {
    final snapshot = await _collection
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => CommunityComment.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> addComment(String postId, CommunityComment comment) async {
    // 댓글 추가
    await _collection
        .doc(postId)
        .collection('comments')
        .add(comment.toFirestore());
    // 글의 commentsCount 증가
    await _collection.doc(postId).update({
      'commentsCount': FieldValue.increment(1),
    });
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required String uid,
    required bool isCurrentlyLiked,
  }) async {
    final ref = _collection.doc(postId);
    if (isCurrentlyLiked) {
      // 좋아요 취소
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likesCount': FieldValue.increment(-1),
      });
    } else {
      // 좋아요 추가
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likesCount': FieldValue.increment(1),
      });
    }
  }
}