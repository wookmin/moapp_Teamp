import 'package:flutter/material.dart';

import '../../data/food_shelf_life_presets.dart';
import '../../models/recognized_food_item.dart';
import '../../services/food_item_recognition_service.dart';
import '../../widgets/common_app_bar.dart';

class ManualFoodAddScreen extends StatefulWidget {
  const ManualFoodAddScreen({super.key});

  @override
  State<ManualFoodAddScreen> createState() => _ManualFoodAddScreenState();
}

class _ManualFoodAddScreenState extends State<ManualFoodAddScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<RecognizedFoodItem> _selectedItems = [];
  final FoodItemRecognitionService _recognitionService =
      const FoodItemRecognitionService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addByName(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final item = _recognitionService.recognizeManualInput(trimmedName);
    if (_selectedItems.any((selected) => selected.name == item.name)) {
      _controller.clear();
      return;
    }

    setState(() {
      _selectedItems.add(item);
      _controller.clear();
    });
  }

  void _removeItem(RecognizedFoodItem item) {
    setState(() {
      _selectedItems.remove(item);
    });
  }

  void _goToConfirm() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('추가할 재료를 먼저 선택해주세요.')));
      return;
    }

    Navigator.of(
      context,
    ).pushNamed('/add-food/confirm', arguments: List.of(_selectedItems));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fridgePresets = foodShelfLifePresets
        .where((preset) => preset.resolvedCandidateType.isDefaultSelected)
        .take(12)
        .toList();

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          Text(
            '무엇을 추가할까요?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '재료를 고르면 소비기한과 보관 방식을 자동으로 제안해요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: _addByName,
            decoration: InputDecoration(
              hintText: '예: 두부, 계란, 대파',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: () => _addByName(_controller.text),
                icon: const Icon(Icons.add_rounded),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '자주 추가하는 재료',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: fridgePresets.map((preset) {
              return ActionChip(
                label: Text(preset.name),
                onPressed: () => _addByName(preset.name),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          if (_selectedItems.isNotEmpty) ...[
            Text(
              '선택한 재료',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _selectedItems.map((item) {
                return InputChip(
                  label: Text(item.name),
                  avatar: const Icon(Icons.kitchen_rounded, size: 18),
                  onDeleted: () => _removeItem(item),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        child: FilledButton(
          onPressed: _goToConfirm,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: Text('선택한 ${_selectedItems.length}개 확인하기'),
        ),
      ),
    );
  }
}
