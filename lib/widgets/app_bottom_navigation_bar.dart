import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({required this.currentRoute, super.key});

  final String currentRoute;

  static const List<_AppNavigationItem> _items = [
    _AppNavigationItem(
      label: '홈',
      routeName: '/',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _AppNavigationItem(
      label: '검색',
      routeName: '/storage-search',
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
    ),
    _AppNavigationItem(
      label: '커뮤니티',
      routeName: '/community',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    _AppNavigationItem(
      label: '쇼핑',
      routeName: '/shopping-recommendations',
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
    ),
    _AppNavigationItem(
      label: '마이페이지',
      routeName: '/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: _items.map((item) {
            final selected = currentRoute == item.routeName;

            return Expanded(
              child: _NavigationItem(
                item: item,
                selected: selected,
                onTap: () => _navigateTo(context, item.routeName),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String routeName) {
    if (routeName == currentRoute) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _AppNavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foregroundColor = selected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                selected ? item.activeIcon : item.icon,
                size: 22,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : foregroundColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppNavigationItem {
  const _AppNavigationItem({
    required this.label,
    required this.routeName,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final String routeName;
  final IconData icon;
  final IconData activeIcon;
}
