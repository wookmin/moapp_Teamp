import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const int _freshnessScore = 82;

  static const List<_UrgentFood> _urgentFoods = [
    _UrgentFood(
      name: '어린 시금치',
      expiryLabel: '유통기한 1일 남음',
      tag: '긴급',
      isUrgent: true,
    ),
    _UrgentFood(
      name: '그릭 요거트',
      expiryLabel: '유통기한 3일 남음',
      tag: '주의',
      isUrgent: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar:
          const AppBottomNavigationBar(currentRoute: '/'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // 헤더: 우리 집 주방 82%
          RichText(
            text: TextSpan(
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
              children: [
                const TextSpan(text: '우리 집 주방 '),
                TextSpan(
                  text: '$_freshnessScore%',
                  style: TextStyle(color: colorScheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '48시간 이내에 소비해야 할 식재료가 12개 있습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // 신선도 게이지 카드
          _FreshnessGaugeCard(score: _freshnessScore),
          const SizedBox(height: 24),

          // 빨리 먹어야 할 음식 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '빨리 먹어야 할 음식',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed('/expiry-management'),
                child: const Text('모두 보기'),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 가로 스크롤 음식 카드
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _urgentFoods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) =>
                  _UrgentFoodCard(food: _urgentFoods[index]),
            ),
          ),
          const SizedBox(height: 24),

          // AI 레시피 추천 카드
          const _AiRecipeCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FreshnessGaugeCard extends StatelessWidget {
  const _FreshnessGaugeCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '신선도 게이지',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _LegendDot(
                        color: colorScheme.primary,
                        label: '최적',
                      ),
                      const SizedBox(width: 16),
                      const _LegendDot(
                        color: Color(0xFFC0392B),
                        label: '위험',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _CircularScore(score: score),
          ],
        ),
      ),
    );
  }
}

class _CircularScore extends StatelessWidget {
  const _CircularScore({required this.score, this.size = 96});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor:
                  AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          Text(
            '$score%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _UrgentFoodCard extends StatelessWidget {
  const _UrgentFoodCard({required this.food});

  final _UrgentFood food;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlight = food.isUrgent
        ? const Color(0xFFFCEAEA)
        : colorScheme.surface;
    final tagColor = food.isUrgent
        ? const Color(0xFFC0392B)
        : colorScheme.primary;

    return SizedBox(
      width: 210,
      child: Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 placeholder
            Container(
              height: 86,
              width: double.infinity,
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.restaurant_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          food.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          food.tag,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tagColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          food.expiryLabel,
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
          ],
        ),
      ),
    );
  }
}

class _AiRecipeCard extends StatelessWidget {
  const _AiRecipeCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B6B47),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 6),
              Text(
                'AI 추천',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '시금치 파스타 어떠세요?',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '시금치가 시들기 전에 15분 만에 완성하는 크리미 시금치 파스타를 '
            '만들 수 있는 모든 재료가 있습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B6B47),
            ),
            child: const Text('요리하기'),
          ),
        ],
      ),
    );
  }
}

class _UrgentFood {
  const _UrgentFood({
    required this.name,
    required this.expiryLabel,
    required this.tag,
    required this.isUrgent,
  });

  final String name;
  final String expiryLabel;
  final String tag;
  final bool isUrgent;
}