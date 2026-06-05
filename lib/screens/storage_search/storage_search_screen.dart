import 'package:flutter/material.dart';

import '../../models/food_item.dart';
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
  late Future<List<FoodItem>> _future;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = AppRepositories.expiry.fetchExpiryItems();
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
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/storage-search',
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddFlow,
              icon: const Icon(Icons.add_rounded),
              label: const Text('추가하기'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _FridgeHeader(onAddPressed: _openAddFlow),
          const SizedBox(height: 18),
          SegmentedButton<int>(
            selected: {_selectedIndex},
            onSelectionChanged: (value) {
              setState(() => _selectedIndex = value.first);
            },
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.kitchen_outlined),
                label: Text('내 냉장고'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.people_alt_outlined),
                label: Text('친구 냉장고'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_selectedIndex == 0)
            FutureBuilder<List<FoodItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 90),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return EmptyStateView(
                    icon: Icons.cloud_off_rounded,
                    title: '냉장고를 불러오지 못했어요',
                    message: snapshot.error.toString().replaceFirst(
                      'Exception: ',
                      '',
                    ),
                    action: TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('다시 시도'),
                    ),
                  );
                }

                final foods = snapshot.data ?? const <FoodItem>[];
                return _MyFridgeBoard(foods: foods, onAddPressed: _openAddFlow);
              },
            )
          else
            const _FriendFridgeMock(),
        ],
      ),
    );
  }
}

class _FridgeHeader extends StatelessWidget {
  const _FridgeHeader({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '냉장고',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '칸별로 식재료를 보고 빠르게 추가하세요.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filled(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              tooltip: '식재료 추가',
            ),
          ],
        ),
      ],
    );
  }
}

class _MyFridgeBoard extends StatelessWidget {
  const _MyFridgeBoard({required this.foods, required this.onAddPressed});

  final List<FoodItem> foods;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final sortedFoods = [...foods]
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (foods.isNotEmpty) ...[
          _FridgeSummary(foods: foods),
          const SizedBox(height: 18),
        ],
        _InteractiveFridge(foods: sortedFoods, onAddPressed: onAddPressed),
        const SizedBox(height: 18),
        if (foods.isEmpty)
          EmptyStateView(
            icon: Icons.add_circle_outline_rounded,
            title: '아직 냉장고가 비어 있어요',
            message: '재료를 추가하면 열린 냉장고 안에 하나씩 채워져요.',
            action: FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('식재료 추가'),
            ),
          )
        else
          _DenseFoodIndex(foods: sortedFoods),
      ],
    );
  }
}

class _FridgeSummary extends StatelessWidget {
  const _FridgeSummary({required this.foods});

  final List<FoodItem> foods;

  @override
  Widget build(BuildContext context) {
    final urgentCount = foods.where((food) => food.isUrgent).length;
    final expiredCount = foods.where((food) => food.daysLeft < 0).length;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _SummaryNumber(label: '전체', value: foods.length.toString()),
          const SizedBox(width: 14),
          _SummaryNumber(label: '임박', value: urgentCount.toString()),
          const SizedBox(width: 14),
          _SummaryNumber(label: '만료', value: expiredCount.toString()),
          const Spacer(),
          Icon(Icons.view_week_rounded, color: colorScheme.onPrimaryContainer),
        ],
      ),
    );
  }
}

class _SummaryNumber extends StatelessWidget {
  const _SummaryNumber({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InteractiveFridge extends StatelessWidget {
  const _InteractiveFridge({required this.foods, required this.onAddPressed});

  final List<FoodItem> foods;
  final VoidCallback onAddPressed;

  static const _slots = [
    Offset(0.17, 0.17),
    Offset(0.30, 0.17),
    Offset(0.43, 0.17),
    Offset(0.56, 0.17),
    Offset(0.69, 0.17),
    Offset(0.20, 0.29),
    Offset(0.34, 0.29),
    Offset(0.48, 0.29),
    Offset(0.62, 0.29),
    Offset(0.76, 0.29),
    Offset(0.17, 0.43),
    Offset(0.30, 0.43),
    Offset(0.43, 0.43),
    Offset(0.56, 0.43),
    Offset(0.69, 0.43),
    Offset(0.20, 0.56),
    Offset(0.34, 0.56),
    Offset(0.48, 0.56),
    Offset(0.62, 0.56),
    Offset(0.76, 0.56),
    Offset(0.18, 0.70),
    Offset(0.31, 0.70),
    Offset(0.44, 0.70),
    Offset(0.57, 0.70),
    Offset(0.70, 0.70),
    Offset(0.24, 0.83),
    Offset(0.38, 0.83),
    Offset(0.52, 0.83),
    Offset(0.66, 0.83),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleFoods = foods.take(_slots.length).toList();
    final hiddenCount = foods.length - visibleFoods.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 0.72,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            const tokenSize = 44.0;

            return Stack(
              children: [
                const _OpenFridgeFrame(),
                if (foods.isEmpty)
                  Center(child: _EmptyFridgeMessage(onAddPressed: onAddPressed))
                else ...[
                  ...visibleFoods.asMap().entries.map((entry) {
                    final slot = _slots[entry.key];
                    final left = (width * slot.dx - tokenSize / 2).clamp(
                      8.0,
                      width - tokenSize - 8,
                    );
                    final top = (height * slot.dy - tokenSize / 2).clamp(
                      10.0,
                      height - tokenSize - 10,
                    );

                    return Positioned(
                      left: left,
                      top: top,
                      width: tokenSize,
                      height: tokenSize,
                      child: _FridgeFoodToken(food: entry.value),
                    );
                  }),
                  if (hiddenCount > 0)
                    Positioned(
                      right: 18,
                      bottom: 18,
                      child: _MoreFoodBadge(count: hiddenCount),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OpenFridgeFrame extends StatelessWidget {
  const _OpenFridgeFrame();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 22,
          right: 76,
          top: 20,
          bottom: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4F5),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD8E0E2), width: 2),
            ),
          ),
        ),
        Positioned(
          right: 18,
          top: 28,
          bottom: 30,
          width: 74,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFA),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(26),
                bottomRight: Radius.circular(26),
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              border: Border.all(color: const Color(0xFFD8E0E2), width: 2),
            ),
          ),
        ),
        ...[0.28, 0.45, 0.64].map(
          (ratio) => Positioned(
            left: 42,
            right: 104,
            top: 20 + ratio * 430,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFC9D3D7).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        Positioned(
          left: 46,
          right: 112,
          bottom: 70,
          height: 72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFC9D3D7)),
            ),
          ),
        ),
        ...[0.20, 0.43, 0.66].map(
          (ratio) => Positioned(
            right: 32,
            top: 72 + ratio * 310,
            width: 42,
            height: 42,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD4DEE1)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyFridgeMessage extends StatelessWidget {
  const _EmptyFridgeMessage({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 190,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.kitchen_outlined, size: 38, color: colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            '빈 냉장고',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '재료를 추가하면 이 안에 하나씩 채워집니다.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

class _FridgeFoodToken extends StatelessWidget {
  const _FridgeFoodToken({required this.food});

  final FoodItem food;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(food);
    final emoji = _emojiFor(food.name);

    return GestureDetector(
      onTap: () => _showFoodDetailSheet(context, food),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 23))),
      ),
    );
  }
}

class _MoreFoodBadge extends StatelessWidget {
  const _MoreFoodBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '+$count개',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DenseFoodIndex extends StatelessWidget {
  const _DenseFoodIndex({required this.foods});

  final List<FoodItem> foods;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '재료 아이콘이나 아래 이름을 누르면 소비기한을 확인할 수 있어요.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: foods.map((food) {
            final color = _statusColor(food);
            return InkWell(
              onTap: () => _showFoodDetailSheet(context, food),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_emojiFor(food.name)),
                    const SizedBox(width: 5),
                    Text(
                      food.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      food.expiryLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

void _showFoodDetailSheet(BuildContext context, FoodItem food) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final statusColor = _statusColor(food);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      _emojiFor(food.name),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        food.storageType.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _FoodDetailRow(
              icon: Icons.event_available_rounded,
              label: '소비기한',
              value: _formatDate(food.expiryDate),
            ),
            _FoodDetailRow(
              icon: Icons.timer_outlined,
              label: '남은 기간',
              value: food.expiryLabel,
              valueColor: statusColor,
            ),
            _FoodDetailRow(
              icon: Icons.flag_rounded,
              label: '상태',
              value: food.statusLabel,
              valueColor: statusColor,
            ),
            if (food.category != null && food.category!.isNotEmpty)
              _FoodDetailRow(
                icon: Icons.category_outlined,
                label: '분류',
                value: food.category!,
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    },
  );
}

class _FoodDetailRow extends StatelessWidget {
  const _FoodDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(FoodItem food) {
  if (food.daysLeft < 0) return const Color(0xFFC94B3E);
  if (food.isUrgent) return const Color(0xFFD9793D);
  if (food.daysLeft <= 7) return const Color(0xFFD0A63A);
  return const Color(0xFF2E8B67);
}

String _emojiFor(String name) {
  if (_containsAny(name, ['우유', '요거트', '치즈'])) return '🥛';
  if (_containsAny(name, ['두부'])) return '◻';
  if (_containsAny(name, ['대파', '파', '상추', '배추', '시금치', '채소'])) return '🥬';
  if (_containsAny(name, ['고기', '삼겹살', '소고기', '돼지고기', '닭'])) return '🥩';
  if (_containsAny(name, ['생선', '고등어', '연어', '오징어'])) return '🐟';
  if (_containsAny(name, ['계란', '달걀'])) return '🥚';
  if (_containsAny(name, ['사과', '딸기', '귤', '오렌지', '바나나', '과일'])) return '🍎';
  if (_containsAny(name, ['고구마', '감자', '당근', '양파', '마늘'])) return '🥕';
  if (_containsAny(name, ['빵', '식빵'])) return '🍞';
  if (_containsAny(name, ['밥', '쌀'])) return '🍚';
  return '🍽';
}

bool _containsAny(String source, List<String> keywords) {
  return keywords.any(source.contains);
}

String _formatDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}.$month.$day';
}

class _FriendFridgeMock extends StatelessWidget {
  const _FriendFridgeMock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const friends = ['여지현'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchBar(
          hintText: '이름으로 친구를 검색하세요',
          leading: const Icon(Icons.search_rounded),
          trailing: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: '친구 추가',
            ),
          ],
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '친구 냉장고 둘러보기',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '친구 기능을 연결하면 친구의 공개 냉장고를 볼 수 있어요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...friends.map((name) => _FriendTile(name: name)),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.star_border_rounded, color: colorScheme.primary),
        title: Text(name),
        subtitle: const Text('공개 냉장고 연결 예정'),
        trailing: OutlinedButton(onPressed: () {}, child: const Text('보기')),
      ),
    );
  }
}
