import '../models/community_comment.dart';
import '../models/community_post.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> fetchPosts({String filter = 'latest'});
  Future<void> addPost(CommunityPost post);

  /// 특정 글의 댓글 목록 (오래된 순)
  Future<List<CommunityComment>> fetchComments(String postId);

  /// 댓글 추가. 글의 commentsCount도 함께 증가시킨다.
  Future<void> addComment(String postId, CommunityComment comment);

  /// 좋아요 토글. [isCurrentlyLiked]가 true면 취소, false면 추가.
  Future<void> toggleLike({
    required String postId,
    required String uid,
    required bool isCurrentlyLiked,
  });

  Future<void> toggleScrap({
    required String postId,
    required String uid,
    required bool isCurrentlyScrapped,
  });

  Future<List<CommunityPost>> fetchScrappedPosts({required String uid});
}
