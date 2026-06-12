import 'package:flutter/material.dart';

import '../screens/community/community_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shopping_recommendations/shopping_recommendations_screen.dart';
import '../screens/storage_search/storage_search_screen.dart';
import '../services/notification_center_service.dart';
import 'app_bottom_navigation_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  static int indexForRoute(String? routeName) {
    return switch (routeName) {
      '/storage-search' => 1,
      '/community' => 2,
      '/shopping-recommendations' => 3,
      '/profile' => 4,
      _ => 0,
    };
  }

  static void selectTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_AppShellState>();
    if (state != null) {
      state.selectTab(index);
      return;
    }

    const routes = [
      '/',
      '/storage-search',
      '/community',
      '/shopping-recommendations',
      '/profile',
    ];
    Navigator.of(context).pushNamedAndRemoveUntil(routes[index], (_) => false);
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    NotificationCenterService.instance.refresh().ignore();
  }

  void selectTab(int index) {
    NotificationCenterService.instance.refresh().ignore();
    if (_currentIndex == index || !mounted) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DashboardScreen(embedded: true),
      const StorageSearchScreen(embedded: true),
      const CommunityScreen(embedded: true),
      const ShoppingRecommendationsScreen(embedded: true),
      ProfileScreen(embedded: true, isActive: _currentIndex == 4),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: selectTab,
      ),
    );
  }
}
