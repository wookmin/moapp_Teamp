import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/food_item.dart';
import '../../repositories/app_repositories.dart';
import '../../services/notification_center_service.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class ExpiryManagementScreen extends StatefulWidget {
  const ExpiryManagementScreen({super.key});

  @override
  State<ExpiryManagementScreen> createState() => _ExpiryManagementScreenState();
}

class _ExpiryManagementScreenState extends State<ExpiryManagementScreen> {
  late Future<List<FoodItem>> _future;
  String _filter = '전체 품목';
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<FoodItem> _getEventsForDay(DateTime day, List<FoodItem> allItems) {
    return allItems.where((f) => _isSameDate(f.expiryDate, day)).toList();
  }

  List<FoodItem> _applyFilter(List<FoodItem> items) {
    if (_selectedDay != null) {
      return items
          .where((f) => _isSameDate(f.expiryDate, _selectedDay!))
          .toList();
    }
    switch (_filter) {
      case '소비기한 임박':
        return items.where((f) => f.isUrgent && f.daysLeft >= 0).toList();
      case '기한 만료':
        return items.where((f) => f.daysLeft < 0).toList();
      default:
        return items;
    }
  }

  Future<void> _openAddFlow() async {
    await Navigator.of(context).pushNamed('/add-food');
    if (mounted) _refresh();
  }

  Future<void> _deleteItem(FoodItem item) async {
    await AppRepositories.expiry.deleteFoodItem(item.id);
    await NotificationCenterService.instance.refresh();
    _refresh();
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      if (_selectedDay != null && _isSameDate(_selectedDay!, selected)) {
        _selectedDay = null;
      } else {
        _selectedDay = selected;
      }
      _focusedDay = focused;
      _filter = '전체 품목';
    });
  }

  void _onFilterTap(String label) {
    setState(() {
      _filter = label;
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      bottomNavigationBar: const AppBottomNavigationBar(currentRoute: '/'),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddFlow,
        child: const Icon(Icons.add_rounded),
      ),
      body: FutureBuilder<List<FoodItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          }

          final allItems = snapshot.data ?? const <FoodItem>[];
          final filteredItems = _applyFilter(allItems);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '소비기한 관리',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/', (route) => false),
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: const Text('홈으로'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── 캘린더 ──
              _ExpiryCalendar(
                focusedDay: _focusedDay,
                selectedDay: _selectedDay,
                allItems: allItems,
                getEventsForDay: (day) => _getEventsForDay(day, allItems),
                onDaySelected: _onDaySelected,
                onPageChanged: (focused) => _focusedDay = focused,
              ),
              const SizedBox(height: 16),

              // ── 선택된 날짜 표시 ──
              if (_selectedDay != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${_selectedDay!.month}월 ${_selectedDay!.day}일 만료 품목',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _selectedDay = null),
                        child: Text(
                          '전체 보기',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── 필터 칩 (날짜 미선택 시) ──
              if (_selectedDay == null) ...[
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: ['전체 품목', '소비기한 임박', '기한 만료'].map((label) {
                    return GestureDetector(
                      onTap: () => _onFilterTap(label),
                      child: _FilterChip(
                        label: label,
                        selected: _filter == label,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // ── 아이템 목록 ──
              if (filteredItems.isEmpty)
                EmptyStateView(
                  icon: Icons.event_note_outlined,
                  title: _selectedDay != null
                      ? '이 날짜에 만료되는 품목이 없어요'
                      : allItems.isEmpty
                          ? '냉장고가 비었어요!'
                          : '해당하는 식품이 없어요',
                  message: _selectedDay != null
                      ? '다른 날짜를 선택해보세요.'
                      : allItems.isEmpty
                          ? '+ 버튼을 눌러 냉장고를 채워주세요 ~'
                          : '다른 필터를 선택해보세요.',
                )
              else
                ...filteredItems.map(
                  (item) => _ExpiryCard(
                    item: item,
                    onDelete: () => _deleteItem(item),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 캘린더
// ──────────────────────────────────────────────

class _ExpiryCalendar extends StatelessWidget {
  const _ExpiryCalendar({
    required this.focusedDay,
    required this.selectedDay,
    required this.allItems,
    required this.getEventsForDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime? selectedDay;
  final List<FoodItem> allItems;
  final List<FoodItem> Function(DateTime) getEventsForDay;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(DateTime) onPageChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: TableCalendar<FoodItem>(
        locale: 'ko_KR',
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2027, 12, 31),
        focusedDay: focusedDay,
        selectedDayPredicate: (day) =>
            selectedDay != null && isSameDay(selectedDay, day),
        calendarFormat: CalendarFormat.month,
        eventLoader: getEventsForDay,
        onDaySelected: onDaySelected,
        onPageChanged: onPageChanged,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w800,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: colorScheme.onSurface,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurface,
          ),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: theme.textTheme.labelSmall!.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
          weekendStyle: theme.textTheme.labelSmall!.copyWith(
            color: colorScheme.error.withValues(alpha: 0.7),
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          todayTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
          selectedDecoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
          weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(
            color: colorScheme.error.withValues(alpha: 0.7),
          ),
          markersMaxCount: 3,
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((food) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _markerColor(food),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _markerColor(FoodItem food) {
    if (food.daysLeft < 0) return const Color(0xFFF04452);
    if (food.daysLeft <= 2) return const Color(0xFFFF8800);
    return const Color(0xFF059669);
  }
}

// ──────────────────────────────────────────────
// 필터 칩
// ──────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? colorScheme.primary : colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: selected ? null : Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 품목 카드 (Slidable)
// ──────────────────────────────────────────────

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.item, required this.onDelete});

  final FoodItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = item.daysLeft < 0
        ? const Color(0xFFF04452)
        : item.isUrgent
            ? const Color(0xFFFF8800)
            : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey(item.id),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          dismissible: DismissiblePane(onDismissed: onDelete),
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: const Color(0xFFF04452),
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              label: '삭제',
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.kitchen_outlined,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.expiryLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}