import 'package:flutter/material.dart';

import '../../models/community_post.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/community',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit_rounded),
      ),
      body: FutureBuilder<List<CommunityPost>>(
        future: AppRepositories.community.fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data ?? const <CommunityPost>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                '실사용 보관 팁과 레시피 아이디어를 탐색하고, 내 노하우도 공유할 수 있어요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _CommunityChip(label: '최신', selected: true),
                  _CommunityChip(label: '인기'),
                  _CommunityChip(label: '내 글'),
                ],
              ),
              const SizedBox(height: 20),
              if (posts.isEmpty)
                const EmptyStateView(
                  icon: Icons.forum_outlined,
                  title: '아직 등록된 보관 팁이 없습니다',
                  message: 'Firebase 커뮤니티 컬렉션을 연결하면 사용자 글과 저장 팁이 표시됩니다.',
                )
              else
                ...posts.map((post) => _CommunityPostCard(post: post)),
            ],
          );
        },
      ),
    );
  }
}

class _CommunityChip extends StatelessWidget {
  const _CommunityChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? colorScheme.primary : colorScheme.surface,
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
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _CommunityChip(label: post.badge, selected: post.badge == '최신'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.author,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(post.excerpt),
            const SizedBox(height: 14),
            Row(
              children: [
                TextButton(onPressed: () {}, child: const Text('상세 보기')),
                TextButton(onPressed: () {}, child: const Text('공유')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
