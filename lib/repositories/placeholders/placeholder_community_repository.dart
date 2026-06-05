import '../../models/community_comment.dart';
import '../../models/community_post.dart';
import '../community_repository.dart';

class PlaceholderCommunityRepository implements CommunityRepository {
  const PlaceholderCommunityRepository();

  @override
  Future<List<CommunityPost>> fetchPosts({String filter = 'latest'}) async =>
      const [];

  @override
  Future<void> addPost(CommunityPost post) async {}

  @override
  Future<List<CommunityComment>> fetchComments(String postId) async => const [];

  @override
  Future<void> addComment(String postId, CommunityComment comment) async {}

  @override
  Future<void> toggleLike({
    required String postId,
    required String uid,
    required bool isCurrentlyLiked,
  }) async {}

  @override
  Future<void> toggleScrap({
    required String postId,
    required String uid,
    required bool isCurrentlyScrapped,
  }) async {}

  @override
  Future<List<CommunityPost>> fetchScrappedPosts({required String uid}) async =>
      const [];
}
