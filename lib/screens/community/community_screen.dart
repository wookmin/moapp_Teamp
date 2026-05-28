import 'package:flutter/material.dart';

import '../../models/community_post.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

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
    if (_selectedFilter == filter) {
      return;
    }

    setState(() {
      _selectedFilter = filter;
      _postsFuture = AppRepositories.community.fetchPosts(filter: filter);
    });
  }

  String get _selectedFilterLabel {
    return _filters
        .firstWhere((filter) => filter.value == _selectedFilter)
        .label;
  }

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            '실사용 보관 팁과 레시피 아이디어를 탐색하고, 내 노하우도 공유할 수 있어요.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
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
          FutureBuilder<List<CommunityPost>>(
            future: _postsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = snapshot.data ?? const <CommunityPost>[];

              if (posts.isEmpty) {
                return EmptyStateView(
                  icon: Icons.forum_outlined,
                  title: '$_selectedFilterLabel 보관 팁이 없습니다',
                  message: 'Firebase 커뮤니티 컬렉션을 연결하면 선택한 필터에 맞는 글이 표시됩니다.',
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
                _PostBadge(label: post.badge),
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

class _PostBadge extends StatelessWidget {
  const _PostBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CommunityFilter {
  const _CommunityFilter({required this.label, required this.value});

  final String label;
  final String value;
}
