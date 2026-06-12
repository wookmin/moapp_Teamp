import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../screens/notifications/notification_center_screen.dart';
import '../services/notification_center_service.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.showBackButton = false,
    this.onNotificationTap,
    this.bellIcon,
  });

  final bool showBackButton;
  final VoidCallback? onNotificationTap;

  /// 커스텀 종 아이콘 (빨간 점 오버레이 등). null이면 기본 아이콘 사용.
  final Widget? bellIcon;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colorScheme.onSurface,
              ),
              tooltip: '뒤로가기',
            )
          : null,
      toolbarHeight: 60,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: showBackButton ? 0 : 20,
      title: SvgPicture.asset('assets/appLogo.svg', height: 27),
      centerTitle: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            onPressed: onNotificationTap ?? () => _openNotifications(context),
            icon: bellIcon ?? _NotificationBell(color: colorScheme.onSurface),
            tooltip: '알림',
          ),
        ),
      ],
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationCenterScreen()),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final service = NotificationCenterService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none_rounded, color: color, size: 24),
            if (service.hasUnread)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  key: const Key('notification-unread-dot'),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE03A47),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
