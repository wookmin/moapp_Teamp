import 'package:flutter/material.dart';

import '../../models/food_item.dart';
import '../../models/freshness_summary.dart';
import '../../models/recipe.dart';
import '../../repositories/app_repositories.dart';
import '../../services/recipe_recommendation_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<FreshnessSummary> _future;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = AppRepositories.dashboard.fetchFreshnessSummary();
    });
  }

  Future<void> _openAddFlow() async {
    await Navigator.of(context).pushNamed('/add-food');
    if (mounted) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(currentRoute: '/'),
      body: FutureBuilder<FreshnessSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final summary =
              snapshot.data ??
              const FreshnessSummary(score: 0, urgentCount: 0, totalCount: 0);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (!summary.hasConnectedData)
                const EmptyStateView(
                  icon: Icons.kitchen_outlined,
                  title: '냉장고가 비었어요!',
                  message: '+ 버튼을 눌러 식품을 추가하면\n신선도, 임박 품목, AI 추천 레시피가 표시됩니다.',
                )
              else ...[
                _DashboardHeader(summary: summary),
                const SizedBox(height: 20),
                _FreshnessGaugeCard(score: summary.score),
                const SizedBox(height: 24),
                _UrgentFoodSection(foods: summary.urgentFoods),
                const SizedBox(height: 24),
                _AiRecipeCard(foods: summary.foods),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFlow,
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
            title: '임박 식품이 없어요 👍',
            message: '냉장고 속 식품이 모두 신선해요!',
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

class _AiRecipeCard extends StatefulWidget {
  const _AiRecipeCard({required this.foods});

  final List<FoodItem> foods;

  @override
  State<_AiRecipeCard> createState() => _AiRecipeCardState();
}

class _AiRecipeCardState extends State<_AiRecipeCard> {
  final RecipeRecommendationService _recommendationService =
      RecipeRecommendationService();
  Future<Recipe?>? _future;

  void _requestRecommendation() {
    setState(() {
      _future = _recommendationService.recommendRecipe(foods: widget.foods);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'AI 추천 레시피',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_future != null)
                GestureDetector(
                  onTap: _requestRecommendation,
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_future == null)
            _AiRecipeIntro(onPressed: _requestRecommendation)
          else
            FutureBuilder<Recipe?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _AiRecipeError(
                    message: snapshot.error.toString().replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    onRetry: _requestRecommendation,
                  );
                }

                final recipe = snapshot.data;
                if (recipe == null) {
                  return _AiRecipeError(
                    message: '추천할 수 있는 레시피 후보가 아직 없어요.',
                    onRetry: _requestRecommendation,
                  );
                }

                return _AiRecipeResult(recipe: recipe);
              },
            ),
        ],
      ),
    );
  }
}

class _AiRecipeIntro extends StatelessWidget {
  const _AiRecipeIntro({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '냉장고 재료로 오늘 먹을 한식 레시피를 추천받아보세요.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '추천 보기 버튼을 눌렀을 때만 AI 추천 요청이 실행됩니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.78),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('AI 추천 보기'),
        ),
      ],
    );
  }
}

class _AiRecipeError extends StatelessWidget {
  const _AiRecipeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI 추천 실패',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('다시 시도'),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
        ),
      ],
    );
  }
}

class _AiRecipeResult extends StatelessWidget {
  const _AiRecipeResult({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          recipe.summary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.5,
          ),
        ),
        if (recipe.ingredients.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '필요한 재료',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: recipe.ingredients
                .map(
                  (ing) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ing,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
        if (recipe.steps.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            '조리 순서',
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...recipe.steps.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 8, top: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
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
