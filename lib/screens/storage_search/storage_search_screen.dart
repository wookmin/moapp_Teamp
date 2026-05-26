import 'package:flutter/material.dart';

import '../../widgets/app_bottom_navigation_bar.dart';
import '../../widgets/common_app_bar.dart';

class StorageSearchScreen extends StatelessWidget {
  const StorageSearchScreen({super.key});

  static const List<_SearchTip> _tips = [
    _SearchTip(title: '딸기', summary: '키친타월을 깔아 밀폐 용기에 담고, 물세척은 먹기 직전에 합니다.', tag: '냉장 2~3일'),
    _SearchTip(title: '우유', summary: '냉장고 문보다는 안쪽 칸에 보관하고 개봉 후에는 빠르게 소비합니다.', tag: '개봉 후 3일'),
    _SearchTip(title: '아스파라거스', summary: '아래쪽을 젖은 키친타월로 감싸 세워두면 수분 유지에 좋아요.', tag: '냉장 5~7일'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      bottomNavigationBar:
          const AppBottomNavigationBar(currentRoute: '/storage-search'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            '재료명을 검색해서 적정 보관법과 소비 팁을 바로 확인하세요.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          SearchBar(
            hintText: '예: 딸기, 우유, 아스파라거스',
            leading: const Icon(Icons.search_rounded),
            enabled: false,
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _SuggestionChip(label: '과일'),
              _SuggestionChip(label: '유제품'),
              _SuggestionChip(label: '채소'),
              _SuggestionChip(label: '냉동 보관'),
            ],
          ),
          const SizedBox(height: 24),
          ..._tips.map((tip) => _SearchTipCard(tip: tip)),
        ],
      ),
    );
  }
}

class _SearchTipCard extends StatelessWidget {
  const _SearchTipCard({
    required this.tip,
  });

  final _SearchTip tip;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tip.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _SuggestionChip(label: tip.tag),
              ],
            ),
            const SizedBox(height: 10),
            Text(tip.summary),
            const SizedBox(height: 14),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('저장'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('공유'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SearchTip {
  const _SearchTip({
    required this.title,
    required this.summary,
    required this.tag,
  });

  final String title;
  final String summary;
  final String tag;
}
