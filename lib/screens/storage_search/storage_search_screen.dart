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
  static const _rulebookCategories = [
    _StorageRulebookCategory(
      title: '육류',
      description: '고기류 보관 기준',
      imagePath: 'assets/categories/meat.jpg',
      ingredients: ['육류'],
    ),
    _StorageRulebookCategory(
      title: '생선류',
      description: '어류와 수산물',
      imagePath: 'assets/categories/seafood.jpg',
      ingredients: ['생선', '어류'],
    ),
    _StorageRulebookCategory(
      title: '유제품·가공',
      description: '우유, 두부, 버터',
      imagePath: 'assets/categories/dairy.jpg',
      ingredients: ['우유', '두부', '버터', '마요네즈'],
    ),
    _StorageRulebookCategory(
      title: '채소',
      description: '잎채소와 뿌리채소',
      imagePath: 'assets/categories/vegetable.jpg',
      ingredients: ['고구마', '대파', '시금치', '무', '양파', '당근', '오이', '마늘', '고추'],
    ),
    _StorageRulebookCategory(
      title: '과일',
      description: '후숙과 냉장 기준',
      imagePath: 'assets/categories/fruit.jpg',
      ingredients: ['사과', '수박', '포도', '멜론', '바나나', '귤', '파인애플'],
    ),
    _StorageRulebookCategory(
      title: '곡류·견과',
      description: '빵과 견과류',
      imagePath: 'assets/categories/grain.jpg',
      ingredients: ['빵', '견과류'],
    ),
  ];

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

  void _selectIngredient(String query) {
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
          _StorageRulebookSection(
            categories: _rulebookCategories,
            onIngredientSelected: _selectIngredient,
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<StorageTip>>(
            future: _tipsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return EmptyStateView(
                  icon: Icons.cloud_off_rounded,
                  title: '검색 데이터를 불러오지 못했어요',
                  message: snapshot.error.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
                );
              }

              final tips = snapshot.data ?? const <StorageTip>[];

              if (_submittedQuery.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.manage_search_rounded,
                  title: '재료명을 검색해보세요',
                  message: '직접 검색하거나 보관 룰북에서 카테고리별 재료를 골라볼 수 있어요.',
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

class _StorageRulebookCategory {
  const _StorageRulebookCategory({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.ingredients,
  });

  final String title;
  final String description;
  final String imagePath;
  final List<String> ingredients;
}

class _StorageRulebookSection extends StatelessWidget {
  const _StorageRulebookSection({
    required this.categories,
    required this.onIngredientSelected,
  });

  final List<_StorageRulebookCategory> categories;
  final ValueChanged<String> onIngredientSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book_rounded, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '보관 룰북',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '카테고리별로 자주 쓰는 식재료 보관법을 빠르게 확인해보세요.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((category) {
                return SizedBox(
                  width: itemWidth,
                  child: _StorageRulebookCard(
                    category: category,
                    onTap: () {
                      _showIngredientSheet(
                        context: context,
                        category: category,
                        onIngredientSelected: onIngredientSelected,
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showIngredientSheet({
    required BuildContext context,
    required _StorageRulebookCategory category,
    required ValueChanged<String> onIngredientSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '확인할 재료를 선택하면 바로 검색 결과로 이동합니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: category.ingredients.map((ingredient) {
                  return ActionChip(
                    label: Text(ingredient),
                    avatar: const Icon(Icons.search_rounded, size: 16),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onIngredientSelected(ingredient);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StorageRulebookCard extends StatelessWidget {
  const _StorageRulebookCard({required this.category, required this.onTap});

  final _StorageRulebookCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카드 상단의 카테고리 사진
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                category.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            // 텍스트 영역
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            if (tip.summary != null) ...[
              const SizedBox(height: 10),
              Text(
                tip.summary!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ],
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