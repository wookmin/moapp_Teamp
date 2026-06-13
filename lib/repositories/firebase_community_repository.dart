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
  Future<List<CommunityPost>> fetchPosts({
    String filter = 'latest',
    String? currentUid,
  }) async {
    if (filter == 'mine' && currentUid == null) {
      return const [];
    }

    Query<Map<String, dynamic>> query = _collection;
    switch (filter) {
      case 'popular':
        query = query.orderBy('likesCount', descending: true).limit(50);
      case 'mine':
        query = query.where('authorUid', isEqualTo: currentUid).limit(50);
      case 'latest':
      default:
        query = query.orderBy('createdAt', descending: true).limit(50);
    }

    final snapshot = await query.get();
    final posts = snapshot.docs
        .map((doc) => CommunityPost.fromFirestore(doc.id, doc.data()))
        .toList();

    if (filter == 'popular') {
      posts.sort((a, b) {
        final likesComparison = b.likesCount.compareTo(a.likesCount);
        if (likesComparison != 0) return likesComparison;
        final commentsComparison = b.commentsCount.compareTo(a.commentsCount);
        if (commentsComparison != 0) return commentsComparison;
        return _compareCreatedAtDescending(a, b);
      });
    } else if (filter == 'mine') {
      posts.sort(_compareCreatedAtDescending);
    }

    return posts;
  }

  static int _compareCreatedAtDescending(CommunityPost a, CommunityPost b) {
    final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  }

  @override
  Future<List<CommunityPost>> fetchScrappedPosts({required String uid}) async {
    final snapshot = await _collection
        .where('scrappedBy', arrayContains: uid)
        .limit(50)
        .get();
    final posts = snapshot.docs
        .map((doc) => CommunityPost.fromFirestore(doc.id, doc.data()))
        .toList();
    posts.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return posts;
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

  @override
  Future<void> toggleScrap({
    required String postId,
    required String uid,
    required bool isCurrentlyScrapped,
  }) async {
    final ref = _collection.doc(postId);
    if (isCurrentlyScrapped) {
      await ref.update({
        'scrappedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'scrappedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }
}
