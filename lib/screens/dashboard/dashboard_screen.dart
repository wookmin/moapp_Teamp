import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../models/food_item.dart';
import '../../models/freshness_summary.dart';
import '../../models/recipe.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/shimmer_card.dart';

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

  Future<void> _showTodayExpiryNotice() async {
    final foods = await AppRepositories.expiry.fetchExpiryItems();

    if (!mounted) return;

    final todayFoods = foods
        .where((food) => _isSameDate(food.expiryDate, DateTime.now()))
        .toList();

    if (todayFoods.isEmpty) {
      _showNotificationCard(
        title: '오늘 만료되는 품목이 없어요',
        message: '냉장고 상태가 좋아요.',
        index: 0,
      );
      return;
    }

    for (var i = 0; i < todayFoods.length; i++) {
      final food = todayFoods[i];

      Future.delayed(Duration(milliseconds: i * 260), () {
        if (!mounted) return;

        _showNotificationCard(
          title: '${food.name}가 곧 상할 수 있어요!!',
          message: '이 품목은 오늘 만료입니다.',
          index: i,
        );
      });
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showNotificationCard({
    required String title,
    required String message,
    required int index,
  }) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10 + (index * 92),
          left: 14,
          right: 14,
          child: _InAppNotificationCard(
            title: title,
            message: message,
            onClose: () => entry.remove(),
          ),
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(onNotificationTap: _showTodayExpiryNotice),
      bottomNavigationBar: const AppBottomNavigationBar(currentRoute: '/'),
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
                  message: '+ 버튼을 눌러 식품을 추가하면\n신선도, 임박 품목, AI 추천 레시피가 표시됩니다.',
                )
              else ...[
                _DashboardHeader(summary: summary),
                const SizedBox(height: 20),
                _FreshnessGaugeCard(summary: summary),
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
  const _FreshnessGaugeCard({required this.summary});

  final FreshnessSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _StatusInfo.fromScore(summary.score);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/expiry-management'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  _CircularScore(score: summary.score, color: status.color),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '우리 집 신선도',
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
                    '지금 확인하기',
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
    final theme = Theme.of(context);

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
        style: theme.textTheme.titleMedium?.copyWith(
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
        icon: hasError
            ? Icons.error_outline_rounded
            : Icons.auto_awesome_outlined,
        title: hasError ? 'AI 추천 실패' : '오늘의 추천 레시피',
        message: hasError ? error! : '식품을 추가하면 재료에 맞는\nAI 추천 레시피가 이곳에 표시돼요.',
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

class _DashboardLoadingView extends StatelessWidget {
  const _DashboardLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: const [
        ShimmerCard(height: 34, width: 220, borderRadius: 12),
        SizedBox(height: 10),
        ShimmerCard(height: 18, width: 280, borderRadius: 9),
        SizedBox(height: 20),
        ShimmerCard(height: 144),
        SizedBox(height: 24),
        ShimmerCard(height: 26, width: 180, borderRadius: 12),
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

class _InAppNotificationCard extends StatelessWidget {
  const _InAppNotificationCard({
    required this.title,
    required this.message,
    required this.onClose,
  });

  final String title;
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onClose,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SvgPicture.asset('assets/appLogo.svg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.close_rounded,
                color: Colors.black38,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
