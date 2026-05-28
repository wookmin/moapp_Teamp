import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';

class ShoppingRecommendationsScreen extends StatelessWidget {
  const ShoppingRecommendationsScreen({super.key});

  static const List<_ShoppingCategory> _categories = [
    _ShoppingCategory(
      title: '신선 식품',
      neededLabel: '3개 품목 필요',
      items: [
        _ShoppingItem(
          name: '유기농 딸기',
          note: '6일 전 마지막 구매',
          tag: '품절',
          status: _StockStatus.out,
        ),
        _ShoppingItem(
          name: '베이비 시금치',
          note: '200g',
          tag: '재고 부족',
          status: _StockStatus.low,
        ),
      ],
    ),
    _ShoppingCategory(
      title: '유제품 및 달걀',
      neededLabel: '2개 품목 필요',
      items: [
        _ShoppingItem(
          name: '우유, 1L',
          note: '폐기 권장',
          tag: '유통기한',
          status: _StockStatus.out,
        ),
        _ShoppingItem(
          name: '방사 유정란',
          note: '2일 남음',
          tag: '재고 부족',
          status: _StockStatus.low,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/shopping-recommendations',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // 스마트 장바구니 배너
          const _SmartCartBanner(),
          const SizedBox(height: 24),

          Text(
            '장보기 추천 리스트',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '냉장고 재고와 소비 습관을 분석한 스마트한 추천입니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          for (final category in _categories) ...[
            _CategorySection(category: category),
            const SizedBox(height: 24),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _SmartCartBanner extends StatelessWidget {
  const _SmartCartBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_basket_rounded,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                '스마트 장바구니',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '48시간 이내에 소진될 것으로 예상되는 6개 품목',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('모두 리스트에 추가'),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final _ShoppingCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              category.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              category.neededLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...category.items.map((item) => _ShoppingItemCard(item: item)),
      ],
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  const _ShoppingItemCard({required this.item});

  final _ShoppingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagColor = item.status == _StockStatus.out
        ? const Color(0xFFC0392B)
        : const Color(0xFFD98A00);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 이미지 placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                color: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.eco_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tagColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.add_shopping_cart_rounded,
                color: colorScheme.primary,
              ),
              tooltip: '장바구니 추가',
            ),
          ],
        ),
      ),
    );
  }
}

enum _StockStatus { out, low }

class _ShoppingCategory {
  const _ShoppingCategory({
    required this.title,
    required this.neededLabel,
    required this.items,
  });

  final String title;
  final String neededLabel;
  final List<_ShoppingItem> items;
}

class _ShoppingItem {
  const _ShoppingItem({
    required this.name,
    required this.note,
    required this.tag,
    required this.status,
  });

  final String name;
  final String note;
  final String tag;
  final _StockStatus status;
}
