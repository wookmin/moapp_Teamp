import 'package:flutter/material.dart';

import '../../models/recognized_food_item.dart';
import '../../repositories/app_repositories.dart';
import '../../services/food_item_recognition_service.dart';
import '../../widgets/common_app_bar.dart';

class FoodAddMethodScreen extends StatelessWidget {
  const FoodAddMethodScreen({super.key});

  static const _recognitionService = FoodItemRecognitionService();

  Future<void> _showComingSoon(BuildContext context, String label) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label 기능은 다음 단계에서 연결할게요.')));
  }

  Future<void> _openRecentFoods(BuildContext context) async {
    final items = await AppRepositories.expiry.fetchExpiryItems();
    if (!context.mounted) {
      return;
    }

    final names = <String>{};
    final recentItems = <RecognizedFoodItem>[];
    for (final item in items.reversed) {
      if (names.add(item.name)) {
        recentItems.add(_recognitionService.recognizeManualInput(item.name));
      }
      if (recentItems.length >= 8) {
        break;
      }
    }

    if (recentItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아직 최근 추가한 재료가 없어요.')));
      return;
    }

    Navigator.of(
      context,
    ).pushNamed('/add-food/confirm', arguments: recentItems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Text(
            '식재료 추가',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '냉장고에 넣을 품목만 골라 저장할 수 있게 정리해드릴게요.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _AddMethodCard(
            icon: Icons.receipt_long_rounded,
            title: '영수증으로 한 번에 추가',
            description: '장본 내역에서 냉장고 품목을 찾아드려요.',
            onTap: () => Navigator.of(context).pushNamed('/add-food/receipt'),
          ),
          _AddMethodCard(
            icon: Icons.qr_code_scanner_rounded,
            title: '바코드 스캔',
            description: '가공식품 정보를 빠르게 불러와요.',
            badge: '다음 단계',
            onTap: () => _showComingSoon(context, '바코드 스캔'),
          ),
          _AddMethodCard(
            icon: Icons.edit_note_rounded,
            title: '직접 추가',
            description: '재료명을 검색하거나 자주 쓰는 재료를 골라요.',
            onTap: () => Navigator.of(context).pushNamed('/add-food/manual'),
          ),
          _AddMethodCard(
            icon: Icons.history_rounded,
            title: '최근 추가한 재료',
            description: '자주 사는 품목을 다시 추가해요.',
            onTap: () => _openRecentFoods(context),
          ),
        ],
      ),
    );
  }
}

class _AddMethodCard extends StatelessWidget {
  const _AddMethodCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(badge!),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
