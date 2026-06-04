class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.author,
    required this.excerpt,
    required this.badge,
    this.imageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.createdAt,
  });

  final String id;
  final String title;
  final String author;
  final String excerpt;
  final String badge;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final DateTime? createdAt;

  Map<String, Object?> toFirestore() => {
    'title': title,
    'author': author,
    'excerpt': excerpt,
    'badge': badge,
    'imageUrl': imageUrl,
    'likesCount': likesCount,
    'commentsCount': commentsCount,
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
      excerpt: data['excerpt'] as String? ?? '',
      badge: data['badge'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      likesCount: (data['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (data['commentsCount'] as num?)?.toInt() ?? 0,
      createdAt: created,
    );
  }

  /// "2시간 전", "3일 전" 같은 상대 시간 라벨
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}주 전';
    if (diff.inDays >= 1) return '${diff.inDays}일 전';
    if (diff.inHours >= 1) return '${diff.inHours}시간 전';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}분 전';
    return '방금 전';
  }

  /// 좋아요·댓글 수를 "1.2k", "856" 형태로 포맷
  String formatCount(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return count.toString();
  }
}