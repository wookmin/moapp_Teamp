import '../models/community_post.dart';

abstract class CommunityRepository {
  Future<List<CommunityPost>> fetchPosts({String filter = 'latest'});
}
