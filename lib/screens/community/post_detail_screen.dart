import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/community_comment.dart';
import '../../models/community_post.dart';
import '../../repositories/app_repositories.dart';

/// 커뮤니티 글 상세 페이지.
/// 좋아요 / 댓글 목록 / 댓글 입력을 함께 제공한다.
class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final CommunityPost post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late CommunityPost _post; // 좋아요 토글 시 갱신
  late Future<List<CommunityComment>> _commentsFuture;

  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;
  bool _isTogglingLike = false;
  bool _isTogglingScrap = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _commentsFuture = AppRepositories.community.fetchComments(_post.id);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _toggleLike() async {
    final uid = _currentUid;
    if (uid == null) {
      _showSnack('좋아요는 로그인 후 가능해요.');
      return;
    }
    if (_isTogglingLike) return;

    final wasLiked = _post.isLikedBy(uid);

    // Optimistic update — UI 먼저 갱신, 실패 시 롤백
    setState(() {
      _isTogglingLike = true;
      _post = CommunityPost(
        id: _post.id,
        title: _post.title,
        author: _post.author,
        excerpt: _post.excerpt,
        badge: _post.badge,
        imageUrl: _post.imageUrl,
        commentsCount: _post.commentsCount,
        createdAt: _post.createdAt,
        likesCount: wasLiked ? _post.likesCount - 1 : _post.likesCount + 1,
        likedBy: wasLiked
            ? (_post.likedBy.where((u) => u != uid).toList())
            : ([..._post.likedBy, uid]),
        scrappedBy: _post.scrappedBy,
      );
    });

    try {
      await AppRepositories.community.toggleLike(
        postId: _post.id,
        uid: uid,
        isCurrentlyLiked: wasLiked,
      );
    } catch (error) {
      if (!mounted) return;
      // 롤백
      setState(() => _post = widget.post);
      _showSnack('좋아요 처리에 실패했어요: $error');
    } finally {
      if (mounted) setState(() => _isTogglingLike = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('댓글은 로그인 후 작성할 수 있어요.');
      return;
    }

    setState(() => _isSubmittingComment = true);

    final authorName =
        user.displayName ?? (user.email ?? '익명').split('@').first;

    final comment = CommunityComment(
      id: '',
      authorName: '@$authorName',
      authorUid: user.uid,
      text: text,
      createdAt: DateTime.now(),
    );

    try {
      await AppRepositories.community.addComment(_post.id, comment);
      if (!mounted) return;
      _commentController.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _post = CommunityPost(
          id: _post.id,
          title: _post.title,
          author: _post.author,
          excerpt: _post.excerpt,
          badge: _post.badge,
          imageUrl: _post.imageUrl,
          likesCount: _post.likesCount,
          likedBy: _post.likedBy,
          scrappedBy: _post.scrappedBy,
          createdAt: _post.createdAt,
          commentsCount: _post.commentsCount + 1,
        );
        _commentsFuture = AppRepositories.community.fetchComments(_post.id);
      });
    } catch (error) {
      if (!mounted) return;
      _showSnack('댓글 작성에 실패했어요: $error');
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _toggleScrap() async {
    final uid = _currentUid;
    if (uid == null) {
      _showSnack('스크랩은 로그인 후 가능해요.');
      return;
    }
    if (_isTogglingScrap) return;

    final wasScrapped = _post.isScrappedBy(uid);
    setState(() {
      _isTogglingScrap = true;
      _post = CommunityPost(
        id: _post.id,
        title: _post.title,
        author: _post.author,
        excerpt: _post.excerpt,
        badge: _post.badge,
        imageUrl: _post.imageUrl,
        likesCount: _post.likesCount,
        likedBy: _post.likedBy,
        commentsCount: _post.commentsCount,
        createdAt: _post.createdAt,
        scrappedBy: wasScrapped
            ? _post.scrappedBy.where((u) => u != uid).toList()
            : [..._post.scrappedBy, uid],
      );
    });

    try {
      await AppRepositories.community.toggleScrap(
        postId: _post.id,
        uid: uid,
        isCurrentlyScrapped: wasScrapped,
      );
      if (mounted) {
        _showSnack(wasScrapped ? '스크랩을 해제했어요.' : '저장된 팁에 추가했어요.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _post = widget.post);
      _showSnack('스크랩 처리에 실패했어요: $error');
    } finally {
      if (mounted) setState(() => _isTogglingScrap = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLiked = _currentUid != null && _post.isLikedBy(_currentUid!);
    final isScrapped = _currentUid != null && _post.isScrappedBy(_currentUid!);

    return Scaffold(
      appBar: AppBar(title: const Text('게시글')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                // 1. 이미지 (있으면)
                if (_post.imageUrl != null && _post.imageUrl!.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      _post.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. 배지
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _post.badge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 3. 제목
                      Text(
                        _post.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 4. 작성자 + 시간
                      Row(
                        children: [
                          Text(
                            _post.author,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _post.timeAgo,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. 본문
                      Text(
                        _post.excerpt,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                          color: colorScheme.onSurface.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 6. 좋아요 / 댓글 카운트 바
                      _LikeAndCountBar(
                        post: _post,
                        isLiked: isLiked,
                        isScrapped: isScrapped,
                        isToggling: _isTogglingLike,
                        isTogglingScrap: _isTogglingScrap,
                        onLikeTap: _toggleLike,
                        onScrapTap: _toggleScrap,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 32),

                // 7. 댓글 섹션
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '댓글 ${_post.commentsCount}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<CommunityComment>>(
                  future: _commentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final comments = snapshot.data ?? const [];
                    if (comments.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Center(
                          child: Text(
                            '첫 댓글을 남겨보세요!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: comments
                          .map((c) => _CommentTile(comment: c))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // 8. 댓글 입력창
          _CommentComposer(
            controller: _commentController,
            isSubmitting: _isSubmittingComment,
            onSubmit: _submitComment,
          ),
        ],
      ),
    );
  }
}

class _LikeAndCountBar extends StatelessWidget {
  const _LikeAndCountBar({
    required this.post,
    required this.isLiked,
    required this.isScrapped,
    required this.isToggling,
    required this.isTogglingScrap,
    required this.onLikeTap,
    required this.onScrapTap,
  });

  final CommunityPost post;
  final bool isLiked;
  final bool isScrapped;
  final bool isToggling;
  final bool isTogglingScrap;
  final VoidCallback onLikeTap;
  final VoidCallback onScrapTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final likeColor = isLiked
        ? const Color(0xFFE03A47)
        : colorScheme.onSurfaceVariant;
    final scrapColor = isScrapped
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        InkWell(
          onTap: isToggling ? null : onLikeTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: likeColor,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  post.formatCount(post.likesCount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: likeColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          post.formatCount(post.commentsCount),
          style: theme.textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: isTogglingScrap ? null : onScrapTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isScrapped
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: scrapColor,
                  size: 22,
                ),
                const SizedBox(width: 6),
                Text(
                  isScrapped ? '저장됨' : '저장',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scrapColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final CommunityComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial = comment.authorName.replaceAll('@', '').trim().characters;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary,
            child: Text(
              initial.isEmpty ? '?' : initial.first.toUpperCase(),
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorName,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요...',
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send_rounded, color: colorScheme.primary),
              tooltip: '댓글 작성',
            ),
          ],
        ),
      ),
    );
  }
}
