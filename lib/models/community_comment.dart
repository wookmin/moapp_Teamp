class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.authorName,
    required this.authorUid,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String authorName;
  final String authorUid;
  final String text;
  final DateTime? createdAt;

  Map<String, Object?> toFirestore() => {
    'authorName': authorName,
    'authorUid': authorUid,
    'text': text,
    'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
  };

  factory CommunityComment.fromFirestore(
    String id,
    Map<String, Object?> data,
  ) {
    final createdRaw = data['createdAt'];
    DateTime? created;
    if (createdRaw is String) {
      created = DateTime.tryParse(createdRaw);
    }
    return CommunityComment(
      id: id,
      authorName: data['authorName'] as String? ?? '',
      authorUid: data['authorUid'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: created,
    );
  }

  /// "2시간 전" 형식
  String get timeAgo {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays >= 7) return '${diff.inDays ~/ 7}주 전';
    if (diff.inDays >= 1) return '${diff.inDays}일 전';
    if (diff.inHours >= 1) return '${diff.inHours}시간 전';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}분 전';
    return '방금 전';
  }
}