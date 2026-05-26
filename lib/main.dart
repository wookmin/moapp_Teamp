import 'package:flutter/material.dart';

import 'screens/community/community_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/expiry_management/expiry_management_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/shopping_recommendations/shopping_recommendations_screen.dart';
import 'screens/storage_search/storage_search_screen.dart';

void main() {
  runApp(const TeamProjectApp());
}

class TeamProjectApp extends StatelessWidget {
  const TeamProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Project',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/expiry-management': (context) => const ExpiryManagementScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/shopping-recommendations': (context) =>
            const ShoppingRecommendationsScreen(),
        '/storage-search': (context) => const StorageSearchScreen(),
        '/community': (context) => const CommunityScreen(),
      },
    );
  }
}
