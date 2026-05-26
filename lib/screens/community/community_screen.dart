import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  static const List<_CommunityPost> _posts = [
    _CommunityPost(title: '딸기 오래 보관하는 방법', author: '냉장고연구소', excerpt: '물세척은 미루고, 키친타월을 한 장 깔아 습기를 먼저 잡아주세요.', badge: '인기'),
    _CommunityPost(title: '우유 유통기한 임박할 때 활용 레시피', author: '홈쿠킹러버', excerpt: '크림 파스타, 프렌치토스트처럼 빠르게 소진 가능한 메뉴를 추천해요.', badge: '최신'),
    _CommunityPost(title: '아스파라거스 식감 살리는 보관 팁', author: '채소마스터', excerpt: '세워서 보관하면 수분이 아래로 몰리지 않아 훨씬 오래 신선합니다.', badge: '내 글'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(currentRoute: '/community'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit_rounded),
      ),
      body: ListView(
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
          ..._posts.map((post) => _CommunityPostCard(post: post)),
        ],
      ),
    );
  }
}

class _CommunityChip extends StatelessWidget {
  const _CommunityChip({
    required this.label,
    this.selected = false,
  });

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
          color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({
    required this.post,
  });

  final _CommunityPost post;

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
                TextButton(
                  onPressed: () {},
                  child: const Text('상세 보기'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('공유'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPost {
  const _CommunityPost({
    required this.title,
    required this.author,
    required this.excerpt,
    required this.badge,
  });

  final String title;
  final String author;
  final String excerpt;
  final String badge;
}
