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
  static const _suggestedQueries = ['우유', '두부', '대파', '계란', '삼겹살', '버섯'];

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

  void _selectSuggestedQuery(String query) {
    _searchController.text = query;
    _submitSearch(query);
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
          ),
          const SizedBox(height: 20),
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
              EdgeInsets.symmetric(horizontal: 18),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => _submitSearch(_searchController.text),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('검색'),
            ),
          ),
          const SizedBox(height: 18),
          _SuggestedQuerySection(
            queries: _suggestedQueries,
            onSelected: _selectSuggestedQuery,
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<StorageTip>>(
            future: _tipsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              final tips = snapshot.data ?? const <StorageTip>[];

              if (_submittedQuery.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.manage_search_rounded,
                  title: '재료명을 검색해보세요',
                  message: '보관 위치, 소비기한 기준, 남은 재료 활용 팁을 한 번에 확인할 수 있어요.',
                );
              }

              if (tips.isEmpty) {
                return EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: '"$_submittedQuery" 결과가 없습니다',
                  message:
                      '아직 등록되지 않은 재료예요. Firebase 보관 팁 DB를 연결하면 더 많은 결과가 표시됩니다.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"$_submittedQuery" 검색 결과 ${tips.length}개',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...tips.map((tip) => _SearchTipCard(tip: tip)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestedQuerySection extends StatelessWidget {
  const _SuggestedQuerySection({
    required this.queries,
    required this.onSelected,
  });

  final List<String> queries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: queries.map((query) {
        return ActionChip(
          label: Text(query),
          avatar: const Icon(Icons.history_rounded, size: 16),
          onPressed: () => onSelected(query),
        );
      }).toList(),
    );
  }
}

class _SearchTipCard extends StatelessWidget {
  const _SearchTipCard({required this.tip});

  final StorageTip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tip.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _SuggestionChip(label: tip.tag),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tip.summary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 16),
            if (tip.storageMethod != null)
              _TipInfoRow(
                icon: Icons.kitchen_rounded,
                title: '보관법',
                body: tip.storageMethod!,
              ),
            if (tip.expiryGuide != null)
              _TipInfoRow(
                icon: Icons.event_available_rounded,
                title: '소비 기준',
                body: tip.expiryGuide!,
              ),
            if (tip.consumeTip != null)
              _TipInfoRow(
                icon: Icons.restaurant_menu_rounded,
                title: '활용 팁',
                body: tip.consumeTip!,
              ),
            const SizedBox(height: 12),
            Text(
              tip.source ?? '보관 팁',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipInfoRow extends StatelessWidget {
  const _TipInfoRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
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
