class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.author,
    this.authorUid,
    required this.excerpt,
    required this.badge,
    this.imageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.likedBy = const [],
    this.scrappedBy = const [],
    this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String? authorUid;
  final String excerpt;
  final String badge;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;

  /// 좋아요를 누른 사용자 uid 목록. 현재 사용자가 좋아요를 눌렀는지 판단할 때 사용.
  final List<String> likedBy;

  /// 스크랩한 사용자 uid 목록. 저장된 팁 목록과 토글 상태를 판단할 때 사용.
  final List<String> scrappedBy;

  final DateTime? createdAt;

  /// 현재 사용자가 이 글에 좋아요를 눌렀는지
  bool isLikedBy(String uid) => likedBy.contains(uid);

  bool isScrappedBy(String uid) => scrappedBy.contains(uid);

  Map<String, Object?> toFirestore() => {
    'title': title,
    'author': author,
    'authorUid': authorUid,
    'excerpt': excerpt,
    'badge': badge,
    'imageUrl': imageUrl,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
    'likedBy': likedBy,
    'scrappedBy': scrappedBy,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory CommunityPost.fromFirestore(String id, Map<String, Object?> data) {
    final createdRaw = data['createdAt'];
    DateTime? created;
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw);
    }
    return CommunityPost(
      id: id,
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      authorUid: data['authorUid'] as String?,
      excerpt: data['excerpt'] as String? ?? '',
      badge: data['badge'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      likedBy: (data['likedBy'] as List?)?.cast<String>() ?? const [],
      scrappedBy: (data['scrappedBy'] as List?)?.cast<String>() ?? const [],
      createdAt: created,
    );
  }

  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}주 전';
    if (diff.inDays >= 1) return '${diff.inDays}일 전';
    if (diff.inHours >= 1) return '${diff.inHours}시간 전';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}분 전';
    return '방금 전';
  }

  String formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return count.toString();
  }
}
