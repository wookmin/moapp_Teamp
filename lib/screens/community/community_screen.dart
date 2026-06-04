import 'package:flutter/material.dart';

import '../../models/community_post.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';
import 'post_compose_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const List<_CommunityFilter> _filters = [
    _CommunityFilter(label: '최신', value: 'latest'),
    _CommunityFilter(label: '인기', value: 'popular'),
    _CommunityFilter(label: '내 글', value: 'mine'),
  ];

  String _selectedFilter = _filters.first.value;
  late Future<List<CommunityPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = AppRepositories.community.fetchPosts(
      filter: _selectedFilter,
    );
  }

  void _selectFilter(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
      _postsFuture = AppRepositories.community.fetchPosts(filter: filter);
    });
  }

  Future<void> _openCompose() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PostComposeScreen()),
    );
    if (created == true && mounted) {
      setState(() {
        _postsFuture = AppRepositories.community.fetchPosts(
          filter: _selectedFilter,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/community',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCompose,
        child: const Icon(Icons.add_rounded),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          // 1. 헤더
          Text(
            '커뮤니티 지혜',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '우리 동네 이웃들의 지속 가능한 보관 비결을 확인해 보세요',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // 2. 검색바 (UI만)
          TextField(
            decoration: InputDecoration(
              hintText: '보관 팁 검색...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),

          // 3. 필터 칩
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filters
                .map(
                  (filter) => _CommunityChip(
                    label: filter.label,
                    selected: _selectedFilter == filter.value,
                    onTap: () => _selectFilter(filter.value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),

          // 4. 게시글 목록
          FutureBuilder<List<CommunityPost>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final posts = snapshot.data ?? const <CommunityPost>[];

              if (posts.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.forum_outlined,
                  title: '아직 글이 없어요',
                  message: '첫 번째 팁을 공유해보세요!',
                );
              }

              return Column(
                children: posts
                    .map((post) => _CommunityPostCard(post: post))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CommunityChip extends StatelessWidget {
  const _CommunityChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 게시글 카드: badge별로 색상/스타일이 달라지고, imageUrl 유무로 이미지/텍스트 카드가 갈린다.
class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPost post;

  /// badge 이름으로 카드 스타일을 결정한다.
  _CardStyle _styleFor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (post.badge) {
      case '주의사항':
        return _CardStyle(
          backgroundColor: const Color(0xFFFCEAEA),
          accentColor: const Color(0xFFC0392B),
          icon: Icons.warning_amber_rounded,
        );
      case '전문가 팁':
        return _CardStyle(
          backgroundColor: colorScheme.surface,
          accentColor: const Color(0xFFD98A00),
          icon: Icons.tips_and_updates_rounded,
        );
      default:
        return _CardStyle(
          backgroundColor: colorScheme.surface,
          accentColor: colorScheme.primary,
          icon: Icons.eco_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = _styleFor(context);
    final hasImage = post.imageUrl != null && post.imageUrl!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: style.backgroundColor,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) _PostImage(url: post.imageUrl!, badge: post.badge),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 + 시간 (이미지 카드만)
                if (hasImage)
                  Row(
                    children: [
                      _AuthorAvatar(name: post.author),
                      const SizedBox(width: 8),
                      Text(
                        post.author,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        post.timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                if (hasImage) const SizedBox(height: 10),

                // 배지 (이미지가 없는 카드만)
                if (!hasImage) ...[
                  Row(
                    children: [
                      Icon(style.icon, size: 18, color: style.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        post.badge,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: style.accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // 제목
                Text(
                  post.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),

                // 본문
                Text(
                  post.excerpt,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),

                // 하단: 좋아요 / 댓글 / (이미지 카드면) 공유, (텍스트 카드면) 작성자
                _PostFooter(post: post, hasImage: hasImage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostImage extends StatelessWidget {
  const _PostImage({required this.url, required this.badge});

  final String url;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 11,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 32,
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: colorScheme.onPrimary),
                const SizedBox(width: 4),
                Text(
                  badge,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
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

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 이름의 첫 글자(또는 @ 뒤 첫 글자)를 아바타에 표시
    final clean = name.replaceAll('@', '').trim();
    final initial = clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
    return CircleAvatar(
      radius: 14,
      backgroundColor: colorScheme.primary,
      child: Text(
        initial,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PostFooter extends StatelessWidget {
  const _PostFooter({required this.post, required this.hasImage});

  final CommunityPost post;
  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(Icons.favorite, size: 18, color: colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          post.formatCount(post.likesCount),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hasImage) ...[
          const SizedBox(width: 14),
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            post.formatCount(post.commentsCount),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.share_outlined, color: colorScheme.onSurfaceVariant),
            tooltip: '공유',
          ),
        ] else ...[
          const Spacer(),
          Text(
            post.author,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _CommunityFilter {
  const _CommunityFilter({required this.label, required this.value});

  final String label;
  final String value;
}

class _CardStyle {
  const _CardStyle({
    required this.backgroundColor,
    required this.accentColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color accentColor;
  final IconData icon;
}