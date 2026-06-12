import 'package:flutter/material.dart';

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

  List<FoodItem> _applyFilter(List<FoodItem> items) {
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
    if (mounted) {
      _refresh();
    }
  }

  Future<void> _deleteItem(FoodItem item) async {
    await AppRepositories.expiry.deleteFoodItem(item.id);
    await NotificationCenterService.instance.refresh();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
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
          final items = _applyFilter(allItems);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '소비기한 관리',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false),
                    icon: const Icon(Icons.home_rounded, size: 18),
                    label: const Text('홈으로'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '냉장고 상태를 카테고리별로 확인하고 먼저 처리할 품목을 빠르게 정리하세요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['전체 품목', '소비기한 임박', '기한 만료'].map((label) {
                  return GestureDetector(
                    onTap: () => setState(() => _filter = label),
                    child: _FilterChip(
                      label: label,
                      selected: _filter == label,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                EmptyStateView(
                  icon: Icons.event_note_outlined,
                  title: allItems.isEmpty ? '냉장고가 비었어요!' : '해당하는 식품이 없어요',
                  message: allItems.isEmpty
                      ? '+ 버튼을 눌러 냉장고를 채워주세요 ~'
                      : '다른 필터를 선택해보세요.',
                )
              else
                ...items.map(
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
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected
              ? colorScheme.onPrimary
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({required this.item, required this.onDelete});

  final FoodItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      child: ListTile(
        leading: Icon(
          Icons.kitchen_outlined,
          color: item.isUrgent ? const Color(0xFFC0392B) : null,
        ),
        title: Text(item.name),
        subtitle: Text(item.expiryLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.statusLabel),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
