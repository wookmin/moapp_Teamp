import 'package:flutter/material.dart';

import '../../models/food_item.dart';
import '../../models/price_trend.dart';
import '../../models/shopping_recommendation.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class ShoppingRecommendationsScreen extends StatelessWidget {
  const ShoppingRecommendationsScreen({super.key});

  /// 현재 냉장고 식재료 이름들을 가져와 Kamis 추천에 필터로 전달한다.
  ///
  /// 추후 파트너가 ExpiryRepository에 history(과거 등록 이력) 기능을 추가하면,
  /// 이 부분에 history names를 합쳐 넘기면 "한 번이라도 등록한 적 있는 품목"까지
  /// 자동으로 필터에 포함된다.
  Future<List<ShoppingCategory>> _loadRecommendations() async {
    Set<String> foodNameHistory = const {};
    try {
      final foods = await AppRepositories.expiry.fetchExpiryItems();
      foodNameHistory = foods.map((FoodItem f) => f.name.trim()).toSet();
    } catch (_) {
      // 로그인 전이거나 ExpiryRepository 호출 실패 시 → 필터 없이 전체 추천
      foodNameHistory = const {};
    }

    return AppRepositories.shoppingRecommendations.fetchRecommendations(
      foodNameHistory: foodNameHistory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/shopping-recommendations',
      ),
      body: FutureBuilder<List<ShoppingCategory>>(
        future: _loadRecommendations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final categories = snapshot.data ?? const <ShoppingCategory>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
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
                '냉장고 품목과 KAMIS 가격 동향을 분석해 살 만한 재료를 추천합니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              if (categories.isEmpty)
                const EmptyStateView(
                  icon: Icons.shopping_cart_outlined,
                  title: '추천 장보기 목록이 없어요',
                  message: '냉장고에 식품을 추가하면\n맞춤 쇼핑 추천이 표시됩니다.',
                )
              else
                for (final category in categories) ...[
                  _CategorySection(category: category),
                  const SizedBox(height: 24),
                ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

/// 식료품 배경 이미지 위에 어두운 오버레이를 깔고, 흰색 텍스트와 버튼을 올린
/// 스마트 장바구니 배너.
class _SmartCartBanner extends StatelessWidget {
  const _SmartCartBanner();

  static const String _backgroundUrl =
      'https://img.freepik.com/premium-photo/shopping-basket-full-fruits-vegetables_53876-157890.jpg';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 168,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 배경 이미지 (실패 시 primaryContainer로 fallback)
            Image.network(
              _backgroundUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(color: colorScheme.primaryContainer);
              },
              errorBuilder: (context, error, stack) =>
                  Container(color: colorScheme.primaryContainer),
            ),
            // 2. 어두운 그라데이션 오버레이 (텍스트 가독성)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xCC0E2E1F), Color(0x66000000)],
                ),
              ),
            ),
            // 3. 컨텐츠
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '스마트 장바구니',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '48시간 이내에 소진될 것으로 예상되는 품목',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: colorScheme.primary,
                      ),
                      child: const Text('모두 리스트에 추가'),
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

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category});

  final ShoppingCategory category;

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
            Expanded(
              child: Text(
                category.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
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

  final ShoppingRecommendation item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagColor = _tagColor(item.status, colorScheme);
    final priceAdvice = _PriceAdvice.fromTrend(item.priceTrend);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ItemThumbnail(imageUrl: item.imageUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _TagChip(label: item.tag, color: tagColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
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
            if (priceAdvice != null) ...[
              const SizedBox(height: 10),
              _PriceAdviceBanner(advice: priceAdvice),
            ],
          ],
        ),
      ),
    );
  }

  static Color _tagColor(StockStatus status, ColorScheme colorScheme) {
    return switch (status) {
      StockStatus.out => const Color(0xFFC0392B),
      StockStatus.low => const Color(0xFFD98A00),
      StockStatus.seasonal => colorScheme.primary,
      StockStatus.priceDrop => const Color(0xFF1E6FD9),
    };
  }
}

class _ItemThumbnail extends StatelessWidget {
  const _ItemThumbnail({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const size = 64.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: size,
        height: size,
        color: colorScheme.surfaceContainerHighest,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? Icon(
                Icons.eco_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 28,
              )
            : Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: size,
                height: size,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Icon(
                  Icons.eco_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 28,
                ),
              ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 카드 하단의 가격 추천 배너
class _PriceAdviceBanner extends StatelessWidget {
  const _PriceAdviceBanner({required this.advice});

  final _PriceAdvice advice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: advice.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: advice.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(advice.icon, size: 16, color: advice.color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              advice.message,
              style: theme.textTheme.labelMedium?.copyWith(
                color: advice.color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (advice.detail != null)
            Text(
              advice.detail!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: advice.color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// PriceTrend로부터 카드 하단에 띄울 추천 메시지를 만든다.
class _PriceAdvice {
  const _PriceAdvice({
    required this.message,
    required this.color,
    required this.icon,
    this.detail,
  });

  final String message;
  final Color color;
  final IconData icon;
  final String? detail;

  static _PriceAdvice? fromTrend(PriceTrend? trend) {
    if (trend == null) return null;
    final label = trend.trendLabel;

    String? detail;
    final rate = trend.changeRate;
    if (rate != null && rate.abs() > 0) {
      detail = '${rate > 0 ? '+' : ''}${rate.toStringAsFixed(1)}%';
    }

    if (label.contains('하락')) {
      return _PriceAdvice(
        message: '지금 사는 것을 추천해요!',
        color: const Color(0xFF1E6FD9),
        icon: Icons.trending_down_rounded,
        detail: detail,
      );
    }
    if (label.contains('상승')) {
      return _PriceAdvice(
        message: '지금은 살 때가 아니에요!',
        color: const Color(0xFFC0392B),
        icon: Icons.trending_up_rounded,
        detail: detail,
      );
    }
    return null;
  }
}