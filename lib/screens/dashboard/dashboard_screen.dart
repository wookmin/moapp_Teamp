import 'package:flutter/material.dart';

import '../../models/food_item.dart';
import '../../models/freshness_summary.dart';
import '../../models/recipe.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(currentRoute: '/'),
      body: FutureBuilder<FreshnessSummary>(
        future: AppRepositories.dashboard.fetchFreshnessSummary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary =
              snapshot.data ?? const FreshnessSummary(score: 0, urgentCount: 0);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (!summary.hasConnectedData)
                const EmptyStateView(
                  icon: Icons.kitchen_outlined,
                  title: '냉장고 데이터 연결 대기 중',
                  message: 'Firebase를 연결하면 신선도, 임박 품목, AI 추천 레시피가 이곳에 표시됩니다.',
                )
              else ...[
                _DashboardHeader(summary: summary),
                const SizedBox(height: 20),
                _FreshnessGaugeCard(score: summary.score),
                const SizedBox(height: 24),
                _UrgentFoodSection(foods: summary.urgentFoods),
                const SizedBox(height: 24),
                _AiRecipeCard(recipe: summary.recommendedRecipe),
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.summary});

  final FreshnessSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
            children: [
              const TextSpan(text: '우리 집 주방 '),
              TextSpan(
                text: '${summary.score}%',
                style: TextStyle(color: colorScheme.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '48시간 이내에 소비해야 할 식재료가 ${summary.urgentCount}개 있습니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FreshnessGaugeCard extends StatelessWidget {
  const _FreshnessGaugeCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '신선도 게이지',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
  const _CircularScore({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const size = 96.0;

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
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
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

class _UrgentFoodSection extends StatelessWidget {
  const _UrgentFoodSection({required this.foods});

  final List<FoodItem> foods;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              onPressed: () =>
                  Navigator.of(context).pushNamed('/expiry-management'),
              child: const Text('모두 보기'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (foods.isEmpty)
          const EmptyStateView(
            icon: Icons.event_available_outlined,
            title: '임박 품목이 없습니다',
            message: 'Firebase 품목 데이터를 연결하면 소비기한이 가까운 식재료가 표시됩니다.',
          )
        else
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: foods.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) =>
                  _UrgentFoodCard(food: foods[index]),
            ),
          ),
      ],
    );
  }
}

class _UrgentFoodCard extends StatelessWidget {
  const _UrgentFoodCard({required this.food});

  final FoodItem food;

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
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.restaurant_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              const Spacer(),
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
                  _Tag(label: food.statusLabel, color: tagColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                food.expiryLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiRecipeCard extends StatelessWidget {
  const _AiRecipeCard({required this.recipe});

  final Recipe? recipe;

  @override
  Widget build(BuildContext context) {
    if (recipe == null) {
      return const EmptyStateView(
        icon: Icons.auto_awesome_outlined,
        title: 'AI 추천 준비 중',
        message: '냉장고 재료, KAMIS 가격 동향, 공공 레시피 DB를 연결하면 오늘의 추천이 표시됩니다.',
      );
    }

    final theme = Theme.of(context);

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
          Text(
            recipe!.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            recipe!.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
