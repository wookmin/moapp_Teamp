import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/community_post.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';
import 'post_detail_screen.dart';

class SavedTipsScreen extends StatefulWidget {
  const SavedTipsScreen({super.key});

  @override
  State<SavedTipsScreen> createState() => _SavedTipsScreenState();
}

class _SavedTipsScreenState extends State<SavedTipsScreen> {
  late Future<List<CommunityPost>> _postsFuture;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _postsFuture = _fetchPosts();
  }

  Future<List<CommunityPost>> _fetchPosts() {
    final uid = _currentUid;
    if (uid == null) return Future.value(const []);
    return AppRepositories.community.fetchScrappedPosts(uid: uid);
  }

  void _refresh() {
    setState(() {
      _postsFuture = _fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
        children: [
          Text(
            '저장된 팁',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '나중에 다시 보고 싶은 커뮤니티 보관 팁을 모아둡니다.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          if (uid == null)
            const EmptyStateView(
              icon: Icons.lock_outline_rounded,
              title: '로그인이 필요해요',
              message: '저장된 팁은 로그인 후 확인할 수 있어요.',
            )
          else
            FutureBuilder<List<CommunityPost>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return EmptyStateView(
                    icon: Icons.error_outline_rounded,
                    title: '저장된 팁을 불러오지 못했어요',
                    message:
                        'Firestore 콘솔 로그에 인덱스 생성 링크가 뜨면 클릭해서 복합 인덱스를 만들어주세요.',
                    action: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('다시 시도'),
                    ),
                  );
                }

                final posts = snapshot.data ?? const [];
                if (posts.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.bookmark_border_rounded,
                    title: '아직 저장한 팁이 없어요',
                    message: '커뮤니티에서 유용한 보관 팁을 스크랩하면 여기에 모입니다.',
                    action: FilledButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/community', (route) => false),
                      child: const Text('커뮤니티 둘러보기'),
                    ),
                  );
                }

                return Column(
                  children: posts
                      .map(
                        (post) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SavedTipCard(
                            post: post,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PostDetailScreen(post: post),
                                ),
                              );
                              if (mounted) _refresh();
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SavedTipCard extends StatelessWidget {
  const _SavedTipCard({required this.post, required this.onTap});

  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      post.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.bookmark_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.excerpt,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
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
                      post.badge,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${post.author} · ${post.timeAgo}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
