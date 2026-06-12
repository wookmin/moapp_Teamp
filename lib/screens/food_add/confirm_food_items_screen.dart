import 'package:flutter/material.dart';

import '../../models/food_candidate_type.dart';
import '../../models/recognized_food_item.dart';
import '../../models/storage_type.dart';
import '../../repositories/app_repositories.dart';
import '../../services/notification_center_service.dart';
import '../../widgets/common_app_bar.dart';

class ConfirmFoodItemsScreen extends StatefulWidget {
  const ConfirmFoodItemsScreen({super.key});

  @override
  State<ConfirmFoodItemsScreen> createState() => _ConfirmFoodItemsScreenState();
}

class _ConfirmFoodItemsScreenState extends State<ConfirmFoodItemsScreen> {
  List<RecognizedFoodItem>? _items;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _items ??=
        (ModalRoute.of(context)?.settings.arguments
            as List<RecognizedFoodItem>?) ??
        const <RecognizedFoodItem>[];
  }

  int get _selectedCount {
    return _items?.where((item) => item.isSelected).length ?? 0;
  }

  Future<void> _saveItems() async {
    final selectedItems =
        _items?.where((item) => item.isSelected).toList() ??
        const <RecognizedFoodItem>[];
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('냉장고에 추가할 품목을 선택해주세요.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      for (final item in selectedItems) {
        await AppRepositories.expiry.addFoodItem(
          name: item.name,
          expiryDate: item.suggestedExpiryDate,
          category: item.category,
          storageType: item.storageType,
        );
      }
      await NotificationCenterService.instance.refresh();

      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) {
        return route.settings.name == '/add-food' || route.isFirst;
      });
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _updateItem(int index, RecognizedFoodItem item) {
    setState(() {
      _items = [...?_items]..[index] = item;
    });
  }

  Future<void> _pickDate(int index, RecognizedFoodItem item) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: item.suggestedExpiryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked == null) {
      return;
    }

    _updateItem(
      index,
      item.copyWith(suggestedExpiryDate: picked, isSelected: true),
    );
  }

  void _quickDate(int index, RecognizedFoodItem item, int days) {
    _updateItem(
      index,
      item.copyWith(
        suggestedExpiryDate: DateTime.now().add(Duration(days: days)),
        isSelected: true,
      ),
    );
  }

  void _switchToFreezer(int index, RecognizedFoodItem item) {
    _updateItem(
      index,
      item.copyWith(
        storageType: StorageType.freezer,
        candidateType: FoodCandidateType.freezer,
        suggestedExpiryDate: DateTime.now().add(const Duration(days: 90)),
        isSelected: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items ?? const <RecognizedFoodItem>[];
    final fridgeItems = _itemsByTypes(items, const [
      FoodCandidateType.fridge,
      FoodCandidateType.freezer,
    ]);
    final pantryItems = _itemsByTypes(items, const [FoodCandidateType.pantry]);
    final excludedItems = _itemsByTypes(items, const [
      FoodCandidateType.nonFood,
      FoodCandidateType.unknown,
    ]);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          Text(
            '인식된 품목을 정리했어요',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '냉장/냉동 식품은 자동으로 선택했고, 실온 식품과 생필품은 제외해뒀어요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          if (items.isEmpty)
            const Center(child: Text('확인할 품목이 없어요.'))
          else ...[
            _Section(
              title: '냉장/냉동 후보',
              items: fridgeItems,
              itemBuilder: _buildItemCard,
            ),
            _Section(
              title: '확인 필요',
              items: pantryItems,
              itemBuilder: _buildItemCard,
            ),
            _Section(
              title: '제외됨',
              items: excludedItems,
              itemBuilder: _buildItemCard,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '포장에 표시된 소비기한이 있다면 그 날짜를 우선으로 설정해주세요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: FilledButton(
          onPressed: _isSaving ? null : _saveItems,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: _isSaving
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('선택한 $_selectedCount개 냉장고에 추가하기'),
        ),
      ),
    );
  }

  List<MapEntry<int, RecognizedFoodItem>> _itemsByTypes(
    List<RecognizedFoodItem> items,
    List<FoodCandidateType> types,
  ) {
    return items.asMap().entries.where((entry) {
      return types.contains(entry.value.candidateType);
    }).toList();
  }

  Widget _buildItemCard(int index, RecognizedFoodItem item) {
    return _ConfirmFoodItemCard(
      item: item,
      onSelectedChanged: (value) {
        _updateItem(index, item.copyWith(isSelected: value));
      },
      onToday: () => _quickDate(index, item, 0),
      onTomorrow: () => _quickDate(index, item, 1),
      onThreeDays: () => _quickDate(index, item, 3),
      onFreezer: () => _switchToFreezer(index, item),
      onPickDate: () => _pickDate(index, item),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.itemBuilder,
  });

  final String title;
  final List<MapEntry<int, RecognizedFoodItem>> items;
  final Widget Function(int index, RecognizedFoodItem item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ...items.map((entry) => itemBuilder(entry.key, entry.value)),
        ],
      ),
    );
  }
}

class _ConfirmFoodItemCard extends StatelessWidget {
  const _ConfirmFoodItemCard({
    required this.item,
    required this.onSelectedChanged,
    required this.onToday,
    required this.onTomorrow,
    required this.onThreeDays,
    required this.onFreezer,
    required this.onPickDate,
  });

  final RecognizedFoodItem item;
  final ValueChanged<bool> onSelectedChanged;
  final VoidCallback onToday;
  final VoidCallback onTomorrow;
  final VoidCallback onThreeDays;
  final VoidCallback onFreezer;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 14, 14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: item.isSelected,
                  onChanged: (value) => onSelectedChanged(value ?? false),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.storageType.label} · ${_formatDate(item.suggestedExpiryDate)}까지',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.note ??
                            '${item.category} · ${item.candidateType.label}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(label: const Text('오늘'), onPressed: onToday),
                  ActionChip(label: const Text('내일'), onPressed: onTomorrow),
                  ActionChip(label: const Text('3일 후'), onPressed: onThreeDays),
                  ActionChip(label: const Text('냉동'), onPressed: onFreezer),
                  ActionChip(label: const Text('수정'), onPressed: onPickDate),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
