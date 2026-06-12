import 'package:flutter/material.dart';

import '../../models/expiry_notification.dart';
import '../../services/notification_center_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _service = NotificationCenterService.instance;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    try {
      await _service.refresh();
      await _service.markAllRead();
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _dismiss(ExpiryNotification item) async {
    try {
      await _service.dismiss(item.key);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('알림을 지우지 못했어요.')));
    }
  }

  Future<void> _confirmDismissAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('알림을 모두 지울까요?'),
        content: const Text('현재 표시된 소비기한 알림이 목록에서 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('모두 지우기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.dismissAll();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('알림을 모두 지우지 못했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _service,
      builder: (context, child) {
        final items = _service.notifications;

        return Scaffold(
          appBar: AppBar(
            title: const Text('알림'),
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              if (items.isNotEmpty)
                TextButton(
                  onPressed: _confirmDismissAll,
                  child: const Text('전체 삭제'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildBody(items),
        );
      },
    );
  }

  Widget _buildBody(List<ExpiryNotification> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_service.isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 36),
              const SizedBox(height: 12),
              const Text('알림을 불러오지 못했어요.'),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('다시 시도')),
            ],
          ),
        ),
      );
    }

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
              '소비기한이 임박하면 여기에 알려드릴게요.',
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
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  '소비기한 알림',
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
        return Dismissible(
          key: ValueKey(item.key),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _dismiss(item),
          background: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(right: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.onError,
            ),
          ),
          child: _NotificationTile(item: item, onDelete: () => _dismiss(item)),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onDelete});

  final ExpiryNotification item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = _NotificationStyle.from(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      decoration: BoxDecoration(
        color: item.isUrgent
            ? style.backgroundColor.withValues(alpha: 0.35)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: item.isUrgent
            ? Border.all(color: style.iconColor.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: style.backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: style.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  style.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: item.isUrgent
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  style.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '알림 삭제',
            icon: const Icon(Icons.close_rounded, size: 19),
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  factory _NotificationStyle.from(ExpiryNotification item) {
    final food = item.food;

    return switch (item.kind) {
      ExpiryNotificationKind.expired => _NotificationStyle(
        icon: Icons.error_rounded,
        backgroundColor: const Color(0xFFFCEAEA),
        iconColor: const Color(0xFFC0392B),
        title: '${food.name} 소비기한 ${-food.daysLeft}일 초과',
        subtitle: '이미 소비기한이 지났어요. 상태를 확인해 주세요.',
      ),
      ExpiryNotificationKind.today => _NotificationStyle(
        icon: Icons.error_rounded,
        backgroundColor: const Color(0xFFFCEAEA),
        iconColor: const Color(0xFFC0392B),
        title: '${food.name} 오늘 만료',
        subtitle: '오늘 안에 소비하는 것을 권장해요.',
      ),
      ExpiryNotificationKind.soon => _NotificationStyle(
        icon: Icons.schedule_rounded,
        backgroundColor: const Color(0xFFFFF4E0),
        iconColor: const Color(0xFFD98A00),
        title: '${food.name} ${food.daysLeft}일 후 만료',
        subtitle: '미리 소비 계획을 세워보세요.',
      ),
      ExpiryNotificationKind.upcoming => _NotificationStyle(
        icon: Icons.info_outline_rounded,
        backgroundColor: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF1B6B47),
        title: '${food.name} ${food.daysLeft}일 후 만료 예정',
        subtitle: '아직 여유가 있어요.',
      ),
    };
  }

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String title;
  final String subtitle;
}
