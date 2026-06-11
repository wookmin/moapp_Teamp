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
  late Future<List<FoodItem>> _foodsFuture;
  int _selectedFridge = 0;

  @override
  void initState() {
    super.initState();
    _foodsFuture = AppRepositories.expiry.fetchExpiryItems();
  }

  void _refresh() {
    setState(() {
      _foodsFuture = AppRepositories.expiry.fetchExpiryItems();
    });
  }

  Future<void> _openAddFood() async {
    await Navigator.of(context).pushNamed('/add-food');
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(
        currentRoute: '/storage-search',
      ),
      floatingActionButton: _selectedFridge == 0
          ? FloatingActionButton.extended(
              onPressed: _openAddFood,
              icon: const Icon(Icons.add_rounded),
              label: const Text('추가하기'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _FridgeHeader(onAddPressed: _openAddFood),
          const SizedBox(height: 18),
          SegmentedButton<int>(
            selected: {_selectedFridge},
            onSelectionChanged: (selection) {
              setState(() => _selectedFridge = selection.first);
            },
            segments: const [
              ButtonSegment<int>(
                value: 0,
                icon: Icon(Icons.kitchen_outlined),
                label: Text('내 냉장고'),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: Icon(Icons.people_alt_outlined),
                label: Text('친구 냉장고'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (_selectedFridge == 0)
            FutureBuilder<List<FoodItem>>(
              future: _foodsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 100),
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
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('다시 시도'),
                    ),
                  );
                }

                final foods = snapshot.data ?? const <FoodItem>[];
                return _MyFridge(foods: foods, onAddPressed: _openAddFood);
              },
            )
          else
            const _FriendFridgeView(),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                '보관 중인 재료와 남은 소비기한을 한눈에 확인하세요.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: onAddPressed,
          icon: const Icon(Icons.add_rounded),
          tooltip: '식재료 추가',
        ),
      ],
    );
  }
}

class _MyFridge extends StatelessWidget {
  const _MyFridge({required this.foods, required this.onAddPressed});

  final List<FoodItem> foods;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final sortedFoods = [...foods]
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return Column(
      children: [
        if (foods.isNotEmpty) ...[
          _FridgeSummary(foods: foods),
          const SizedBox(height: 18),
        ],
        _FridgeCabinet(foods: sortedFoods, onAddPressed: onAddPressed),
        if (foods.isEmpty) ...[
          const SizedBox(height: 18),
          EmptyStateView(
            icon: Icons.kitchen_outlined,
            title: '아직 냉장고가 비어 있어요',
            message: '재료를 추가하면 냉장고 안에 하나씩 채워집니다.',
            action: FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('식재료 추가'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '재료를 누르면 소비기한을 자세히 볼 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FridgeSummary extends StatelessWidget {
  const _FridgeSummary({required this.foods});

  final List<FoodItem> foods;

  @override
  Widget build(BuildContext context) {
    final urgent = foods.where((food) => food.isUrgent).length;
    final expired = foods.where((food) => food.daysLeft < 0).length;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _SummaryValue(label: '전체', value: foods.length),
          const SizedBox(width: 22),
          _SummaryValue(label: '임박', value: urgent),
          const SizedBox(width: 22),
          _SummaryValue(label: '만료', value: expired),
          const Spacer(),
          Icon(Icons.view_week_rounded, color: colorScheme.onPrimaryContainer),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FridgeCabinet extends StatelessWidget {
  const _FridgeCabinet({required this.foods, required this.onAddPressed});

  final List<FoodItem> foods;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleFoods = foods.take(24).toList();
    final hiddenCount = foods.length - visibleFoods.length;

    return Container(
      width: double.infinity,
      height: 500,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFEFE), Color(0xFFEAF1F2)],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFFCBD6D9), width: 2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: foods.isEmpty
          ? _EmptyFridge(onAddPressed: onAddPressed)
          : Column(
              children: [
                for (var shelf = 0; shelf < 4; shelf++) ...[
                  Expanded(
                    child: _FridgeShelf(
                      foods: visibleFoods.skip(shelf * 6).take(6).toList(),
                    ),
                  ),
                  if (shelf != 3)
                    Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBECBCD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
                if (hiddenCount > 0)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+$hiddenCount개',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _FridgeShelf extends StatelessWidget {
  const _FridgeShelf({required this.foods});

  final List<FoodItem> foods;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: foods
          .map(
            (food) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _FoodToken(food: food),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FoodToken extends StatelessWidget {
  const _FoodToken({required this.food});

  final FoodItem food;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(food);

    return InkWell(
      onTap: () => _showFoodDetail(context, food),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(_emojiFor(food.name), style: const TextStyle(fontSize: 27)),
            const SizedBox(height: 4),
            Text(
              food.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              food.expiryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFridge extends StatelessWidget {
  const _EmptyFridge({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.kitchen_outlined, size: 54, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            '빈 냉장고',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '재료를 추가해 냉장고를 채워보세요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('추가하기'),
          ),
        ],
      ),
    );
  }
}

class _FriendFridgeView extends StatelessWidget {
  const _FriendFridgeView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        ),
        const SizedBox(height: 20),
        EmptyStateView(
          icon: Icons.people_outline_rounded,
          title: '아직 연결된 친구가 없어요',
          message: '친구 기능을 연결하면 친구의 냉장고를 구경하고 재료를 함께 확인할 수 있어요.',
          action: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_search_rounded),
            label: const Text('친구 찾기'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '친구 냉장고는 다음 업데이트에서 연결됩니다.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

void _showFoodDetail(BuildContext context, FoodItem food) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final statusColor = _statusColor(food);

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _emojiFor(food.name),
                      style: const TextStyle(fontSize: 30),
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
              _DetailRow(label: '소비기한', value: _formatDate(food.expiryDate)),
              _DetailRow(
                label: '남은 기간',
                value: food.expiryLabel,
                valueColor: statusColor,
              ),
              _DetailRow(
                label: '상태',
                value: food.statusLabel,
                valueColor: statusColor,
              ),
              if (food.category?.isNotEmpty == true)
                _DetailRow(label: '분류', value: food.category!),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(FoodItem food) {
  if (food.daysLeft < 0) return const Color(0xFFB3261E);
  if (food.daysLeft <= 2) return const Color(0xFFD95F2B);
  if (food.daysLeft <= 7) return const Color(0xFF9A7200);
  return const Color(0xFF19734B);
}

String _formatDate(DateTime date) {
  return '${date.year}.${date.month.toString().padLeft(2, '0')}.'
      '${date.day.toString().padLeft(2, '0')}';
}

String _emojiFor(String name) {
  if (name.contains('우유')) return '🥛';
  if (name.contains('요거트') || name.contains('요구르트')) return '🥣';
  if (name.contains('두부')) return '⬜';
  if (name.contains('달걀') || name.contains('계란')) return '🥚';
  if (name.contains('고기') || name.contains('삼겹') || name.contains('소고기')) {
    return '🥩';
  }
  if (name.contains('생선') || name.contains('고등어')) return '🐟';
  if (name.contains('사과')) return '🍎';
  if (name.contains('딸기')) return '🍓';
  if (name.contains('바나나')) return '🍌';
  if (name.contains('포도')) return '🍇';
  if (name.contains('당근')) return '🥕';
  if (name.contains('버섯')) return '🍄';
  if (name.contains('양파')) return '🧅';
  if (name.contains('마늘')) return '🧄';
  if (name.contains('고추') || name.contains('파프리카')) return '🌶️';
  if (name.contains('빵')) return '🍞';
  if (name.contains('밥')) return '🍚';
  return '🥬';
}
