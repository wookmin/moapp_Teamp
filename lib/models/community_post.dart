class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.author,
    required this.excerpt,
    required this.badge,
  });

  final String id;
  final String title;
  final String author;
  final String excerpt;
  final String badge;

  Map<String, Object?> toFirestore() => {
        'title': title,
        'author': author,
        'excerpt': excerpt,
        'badge': badge,
        'createdAt': DateTime.now().toIso8601String(),
      };

  factory CommunityPost.fromFirestore(String id, Map<String, Object?> data) {
    return CommunityPost(
      id: id,
      title: data['title'] as String? ?? '',
      author: data['author'] as String? ?? '',
      excerpt: data['excerpt'] as String? ?? '',
      badge: data['badge'] as String? ?? '',
    );
  }
}
