import '../../models/community_post.dart';
import '../community_repository.dart';

class PlaceholderCommunityRepository implements CommunityRepository {
  const PlaceholderCommunityRepository();

  @override
  Future<List<CommunityPost>> fetchPosts({String filter = 'latest'}) async => const [];

  @override
  Future<void> addPost(CommunityPost post) async {}
}
