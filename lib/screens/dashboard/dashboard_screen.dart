import 'package:flutter/material.dart';

import '../../models/food_item.dart';
import '../../models/freshness_summary.dart';
import '../../models/recipe.dart';
import '../../repositories/app_repositories.dart';
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

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    DateTime? selectedDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('식품 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '식품 이름'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate == null
                          ? '소비기한 선택'
                          : '${selectedDate!.year}.${selectedDate!.month.toString().padLeft(2, '0')}.${selectedDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: const Text('날짜 선택'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true &&
        nameController.text.trim().isNotEmpty &&
        selectedDate != null) {
      await AppRepositories.expiry.addFoodItem(
        name: nameController.text.trim(),
        expiryDate: selectedDate!,
      );
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
              snapshot.data ?? const FreshnessSummary(score: 0, urgentCount: 0, totalCount: 0);

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
                _AiRecipeCard(
                  recipe: summary.recommendedRecipe,
                  error: summary.recipeError,
                  onRefresh: _refresh,
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
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

class _AiRecipeCard extends StatelessWidget {
  const _AiRecipeCard({
    required this.recipe,
    required this.onRefresh,
    this.error,
  });

  final Recipe? recipe;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    if (recipe == null) {
      final hasError = error != null;
      return EmptyStateView(
        icon: hasError ? Icons.error_outline_rounded : Icons.auto_awesome_outlined,
        title: hasError ? 'AI 추천 실패' : '오늘의 추천 레시피',
        message: hasError
            ? error!
            : '식품을 추가하면 재료에 맞는\nAI 추천 레시피가 이곳에 표시돼요.',
        action: TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('다시 시도'),
        ),
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
              GestureDetector(
                onTap: onRefresh,
                child: const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          if (recipe!.ingredients.isNotEmpty) ...[
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
              children: recipe!.ingredients
                  .map((ing) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                      ))
                  .toList(),
            ),
          ],
          if (recipe!.steps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '조리 순서',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
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
