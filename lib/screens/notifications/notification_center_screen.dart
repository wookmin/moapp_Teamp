import 'package:flutter/material.dart';

import '../../repositories/app_repositories.dart';

/// 알림 센터 화면 — 토스/카카오 스타일
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late Future<List<_NotificationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _buildNotifications();
  }

  Future<List<_NotificationItem>> _buildNotifications() async {
    final foods = await AppRepositories.expiry.fetchExpiryItems();
    final items = <_NotificationItem>[];

    // 오늘 만료
    final expired = foods.where((f) => f.daysLeft <= 0).toList();
    for (final f in expired) {
      items.add(_NotificationItem(
        icon: Icons.error_rounded,
        iconBgColor: const Color(0xFFFCEAEA),
        iconColor: const Color(0xFFC0392B),
        title: f.daysLeft < 0
            ? '${f.name} 유통기한 ${-f.daysLeft}일 초과'
            : '${f.name} 오늘 만료',
        subtitle: f.daysLeft < 0
            ? '이미 유통기한이 지났어요. 상태를 확인해 주세요.'
            : '오늘 안에 소비하는 것을 권장해요.',
        timeAgo: '오늘',
        isUrgent: true,
      ));
    }

    // 1~2일 이내 임박
    final soon = foods.where((f) => f.daysLeft > 0 && f.daysLeft <= 2).toList();
    for (final f in soon) {
      items.add(_NotificationItem(
        icon: Icons.schedule_rounded,
        iconBgColor: const Color(0xFFFFF4E0),
        iconColor: const Color(0xFFD98A00),
        title: '${f.name} ${f.daysLeft}일 후 만료',
        subtitle: '미리 소비 계획을 세워보세요.',
        timeAgo: '오늘',
        isUrgent: false,
      ));
    }

    // 3~5일 이내 참고
    final upcoming = foods.where((f) => f.daysLeft > 2 && f.daysLeft <= 5).toList();
    for (final f in upcoming) {
      items.add(_NotificationItem(
        icon: Icons.info_outline_rounded,
        iconBgColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF1B6B47),
        title: '${f.name} ${f.daysLeft}일 후 만료 예정',
        subtitle: '아직 여유가 있어요.',
        timeAgo: '오늘',
        isUrgent: false,
      ));
    }

    // 정렬: 급한 순서
    items.sort((a, b) {
      if (a.isUrgent && !b.isUrgent) return -1;
      if (!a.isUrgent && b.isUrgent) return 1;
      return 0;
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림'),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: FutureBuilder<List<_NotificationItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_off_outlined,
                      size: 32,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '새로운 알림이 없어요',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '유통기한이 임박하면 여기에 알려드릴게요.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: items.length + 1, // +1 for section header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        '오늘',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${items.length}건',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final item = items[index - 1];
              return _NotificationTile(item: item);
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.isUrgent
            ? item.iconBgColor.withValues(alpha: 0.35)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: item.isUrgent
            ? Border.all(color: item.iconColor.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: item.isUrgent ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              item.timeAgo,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    required this.isUrgent,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool isUrgent;
}
