import 'package:flutter/material.dart';

import '../../models/storage_tip.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class StorageSearchScreen extends StatefulWidget {
  const StorageSearchScreen({super.key});

  @override
  State<StorageSearchScreen> createState() => _StorageSearchScreenState();
}

class _StorageSearchScreenState extends State<StorageSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<StorageTip>> _tipsFuture;
  String _submittedQuery = '';

  @override
  void initState() {
    super.initState();
    _tipsFuture = AppRepositories.storageSearch.searchStorageTips('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    final query = value.trim();

    setState(() {
      _submittedQuery = query;
      _tipsFuture = AppRepositories.storageSearch.searchStorageTips(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _submitSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/storage-search',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            '재료명을 검색해서 적정 보관법과 소비 팁을 바로 확인하세요.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          SearchBar(
            controller: _searchController,
            hintText: '예: 딸기, 우유, 아스파라거스',
            leading: const Icon(Icons.search_rounded),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: '검색어 지우기',
                ),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: _submitSearch,
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _submitSearch(_searchController.text),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('검색'),
            ),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<StorageTip>>(
            future: _tipsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final tips = snapshot.data ?? const <StorageTip>[];

              if (tips.isEmpty) {
                return EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: _submittedQuery.isEmpty
                      ? '검색 결과가 없습니다'
                      : '"$_submittedQuery" 결과가 없습니다',
                  message: _submittedQuery.isEmpty
                      ? '검색어를 입력하면 보관 팁 Repository를 통해 결과를 불러옵니다.'
                      : '식약처 레시피 DB와 Firebase 보관 팁을 연결하면 관련 결과가 표시됩니다.',
                );
              }

              return Column(
                children: tips.map((tip) => _SearchTipCard(tip: tip)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SearchTipCard extends StatelessWidget {
  const _SearchTipCard({required this.tip});

  final StorageTip tip;

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
                    tip.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SuggestionChip(label: tip.tag),
              ],
            ),
            const SizedBox(height: 10),
            Text(tip.summary),
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton(onPressed: () {}, child: const Text('저장')),
                const SizedBox(width: 8),
                TextButton(onPressed: () {}, child: const Text('공유')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
