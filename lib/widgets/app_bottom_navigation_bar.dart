import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    this.currentRoute,
    this.selectedIndex,
    this.onDestinationSelected,
  });

  final String? currentRoute;
  final int? selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  static const List<_AppNavigationItem> _items = [
    _AppNavigationItem(
      label: '홈',
      routeName: '/',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _AppNavigationItem(
      label: '냉장고',
      routeName: '/storage-search',
      icon: Icons.kitchen_outlined,
      activeIcon: Icons.kitchen_rounded,
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
    final resolvedIndex =
        selectedIndex ??
        _items
            .indexWhere((item) => item.routeName == currentRoute)
            .clamp(0, _items.length - 1);

    return NavigationBar(
      selectedIndex: resolvedIndex,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected:
          onDestinationSelected ??
          (index) => _navigateTo(context, _items[index].routeName),
      destinations: _items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }

  void _navigateTo(BuildContext context, String routeName) {
    if (routeName == currentRoute) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
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
