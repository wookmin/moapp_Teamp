import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
            onPressed: onNotificationTap,
            icon:
                bellIcon ??
                Icon(
                  Icons.notifications_none_rounded,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
            tooltip: '알림',
          ),
        ),
      ],
    );
  }
}
