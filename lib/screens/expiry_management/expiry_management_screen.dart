import 'package:flutter/material.dart';

import '../../models/food_item.dart';
import '../../repositories/app_repositories.dart';
import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';
import '../../widgets/empty_state_view.dart';

class ExpiryManagementScreen extends StatelessWidget {
  const ExpiryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar: const AppBottomNavigationBar(currentRoute: '/'),
      body: FutureBuilder<List<FoodItem>>(
        future: AppRepositories.expiry.fetchExpiryItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <FoodItem>[];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                '냉장고 상태를 카테고리별로 확인하고 먼저 처리할 품목을 빠르게 정리하세요.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FilterChip(label: '전체 품목', selected: true),
                  _FilterChip(label: '소비기한 임박'),
                  _FilterChip(label: '기한 만료'),
                ],
              ),
              const SizedBox(height: 20),
              if (items.isEmpty)
                const EmptyStateView(
                  icon: Icons.event_note_outlined,
                  title: '소비기한 품목이 없습니다',
                  message: 'Firebase 냉장고 데이터를 연결하면 전체/임박/만료 품목을 필터링할 수 있습니다.',
                )
              else
                ...items.map((item) => _ExpiryCard(item: item)),
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
  const _ExpiryCard({required this.item});

  final FoodItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.kitchen_outlined),
        title: Text(item.name),
        subtitle: Text(item.expiryLabel),
        trailing: Text(item.statusLabel),
      ),
    );
  }
}
