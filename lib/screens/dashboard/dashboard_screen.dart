import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../models/food_item.dart';
import '../../models/freshness_summary.dart';
import '../../models/recipe.dart';
import '../../repositories/app_repositories.dart';
import '../../services/notification_center_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/food_icon.dart';
import '../../widgets/shimmer_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<FreshnessSummary> _future;
  Recipe? _recommendedRecipe;
  String? _recipeError;
  bool _isRecipeLoading = false;
  bool _hasRequestedRecipe = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = AppRepositories.dashboard.fetchFreshnessSummary();
      _recommendedRecipe = null;
      _recipeError = null;
      _isRecipeLoading = false;
      _hasRequestedRecipe = false;
    });
  }

  Future<void> _requestRecipe(List<FoodItem> foods) async {
    if (_isRecipeLoading || foods.isEmpty) return;

    setState(() {
      _isRecipeLoading = true;
      _hasRequestedRecipe = true;
      _recipeError = null;
    });

    try {
      final recipe = await AppRepositories.dashboard.recommendRecipe(foods);
      if (!mounted) return;
      setState(() {
        _recommendedRecipe = recipe;
        if (recipe == null) {
          _recipeError = '추천할 레시피를 찾지 못했어요. 다시 시도해주세요.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _recommendedRecipe = null;
        _recipeError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isRecipeLoading = false);
      }
    }
  }

  Future<void> _openAddFlow() async {
    await Navigator.of(context).pushNamed('/add-food');
    if (mounted) {
      _refresh();
      NotificationCenterService.instance.refresh().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: widget.embedded
          ? null
          : const AppBottomNavigationBar(currentRoute: '/'),
      body: FutureBuilder<FreshnessSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _DashboardLoadingView();
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
                  message: '+ 버튼을 눌러 식품을 추가하면\n신선도, 임박 품목, 오늘의 추천이 표시됩니다.',
                )
              else ...[
                _FreshnessGaugeCard(summary: summary),
                const SizedBox(height: 24),
                _UrgentFoodSection(foods: summary.urgentFoods),
                const SizedBox(height: 24),
                _AiRecipeCard(
                  recipe: _recommendedRecipe,
                  error: _recipeError,
                  isLoading: _isRecipeLoading,
                  hasRequested: _hasRequestedRecipe,
                  onRequest: () => _requestRecipe(summary.foods),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFlow,
        heroTag: 'dashboard-add-food',
        tooltip: '식재료 추가',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _FreshnessGaugeCard extends StatelessWidget {
  const _FreshnessGaugeCard({required this.summary});
  final FreshnessSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _StatusInfo.fromScore(summary.score);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/expiry-management'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '오늘의 냉장고',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary.urgentCount == 0
                    ? '지금 처리할 재료가 없어요'
                    : '먼저 확인할 재료 ${summary.urgentCount}개',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _CircularScore(score: summary.score, color: status.color),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '신선도',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status.message,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            children: [
                              const TextSpan(text: '곧 상할 식재료 '),
                              TextSpan(
                                text: '${summary.urgentCount}개',
                                style: TextStyle(
                                  color: status.color,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '소비기한 전체 보기',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircularScore extends StatelessWidget {
  const _CircularScore({required this.score, required this.color});
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: 38,
      lineWidth: 8,
      percent: (score / 100).clamp(0.0, 1.0),
      animation: true,
      animationDuration: 900,
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: color,
      backgroundColor: const Color(0xFFF1EFE8),
      center: Text(
        '$score%',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _StatusInfo {
  const _StatusInfo({required this.message, required this.color});
  final String message;
  final Color color;

  factory _StatusInfo.fromScore(int score) {
    if (score >= 80) {
      return const _StatusInfo(message: '신선해요', color: Color(0xFF1B6B47));
    }
    if (score >= 50) {
      return const _StatusInfo(message: '조심하세요', color: Color(0xFFD98A00));
    }
    return const _StatusInfo(message: '관리가 필요해요', color: Color(0xFFC0392B));
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
            title: '임박 식품이 없어요!',
            message: '냉장고 속 식품이 모두 신선해요!',
          )
        else
          Column(
            children: foods
                .take(3)
                .map(
                  (food) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _UrgentFoodCard(food: food),
                  ),
                )
                .toList(),
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

    return Card(
      clipBehavior: Clip.antiAlias,
      color: highlight,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/expiry-management'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  foodIconFor(food.name, category: food.category),
                  color: tagColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      food.expiryLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _Tag(label: food.statusLabel, color: tagColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiRecipeCard extends StatelessWidget {
  const _AiRecipeCard({
    required this.recipe,
    required this.isLoading,
    required this.hasRequested,
    required this.onRequest,
    this.error,
  });
  final Recipe? recipe;
  final String? error;
  final bool isLoading;
  final bool hasRequested;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _RecipeLoadingCard();
    }

    if (recipe == null) {
      final hasError = error != null;
      return EmptyStateView(
        icon: hasError
            ? Icons.error_outline_rounded
            : Icons.soup_kitchen_outlined,
        title: hasError
            ? '추천을 불러오지 못했어요'
            : hasRequested
            ? '추천 결과가 없어요'
            : '오늘 뭐 먹을지 고민되나요?',
        message: hasError ? error! : '버튼을 누르면 냉장고 재료로 만들 수 있는 요리를 추천해드려요.',
        action: FilledButton.icon(
          onPressed: onRequest,
          icon: Icon(
            hasError ? Icons.refresh_rounded : Icons.soup_kitchen_outlined,
            size: 18,
          ),
          label: Text(hasError ? '다시 추천받기' : '레시피 추천받기'),
        ),
      );
    }

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F3EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E4D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.soup_kitchen_outlined,
                color: Color(0xFF087A52),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                '냉장고 재료로 만든 오늘의 추천',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF075D41),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onRequest,
                tooltip: '다른 레시피 추천받기',
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF087A52),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recipe!.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: const Color(0xFF17201B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            recipe!.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF47534B),
              height: 1.5,
            ),
          ),
          if (recipe!.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '필요한 재료',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF17201B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: recipe!.ingredients
                  .map(
                    (ing) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        ing,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF075D41),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (recipe!.steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '조리 순서',
              style: theme.textTheme.labelLarge?.copyWith(
                color: const Color(0xFF17201B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...recipe!.steps.asMap().entries.map(
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
                        color: const Color(0xFF087A52),
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
                          color: const Color(0xFF47534B),
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
      ),
    );
  }
}

class _RecipeLoadingCard extends StatelessWidget {
  const _RecipeLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('레시피를 찾고 있어요', style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '현재 냉장고 재료를 기준으로 추천을 만들고 있습니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
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

class _DashboardLoadingView extends StatelessWidget {
  const _DashboardLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: const [
        ShimmerCard(height: 34, borderRadius: 12),
        SizedBox(height: 10),
        ShimmerCard(height: 18, borderRadius: 9),
        SizedBox(height: 20),
        ShimmerCard(height: 144),
        SizedBox(height: 24),
        ShimmerCard(height: 26, borderRadius: 12),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: ShimmerCard(height: 168)),
            SizedBox(width: 14),
            Expanded(child: ShimmerCard(height: 168)),
          ],
        ),
        SizedBox(height: 24),
        ShimmerCard(height: 190),
      ],
    );
  }
}
