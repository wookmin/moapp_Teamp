import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/auth/auth_gate.dart';
import 'screens/community/community_screen.dart';
import 'screens/expiry_management/expiry_management_screen.dart';
import 'screens/food_add/confirm_food_items_screen.dart';
import 'screens/food_add/food_add_method_screen.dart';
import 'screens/food_add/manual_food_add_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/shopping_recommendations/shopping_recommendations_screen.dart';
import 'screens/storage_search/storage_search_screen.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await FirebaseBootstrap.initialize();
  runApp(const TeamProjectApp());
}

class TeamProjectApp extends StatelessWidget {
  const TeamProjectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Team Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D8B5B),
          surface: const Color(0xFFF5F7F2),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F2),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/add-food': (context) => const FoodAddMethodScreen(),
        '/add-food/manual': (context) => const ManualFoodAddScreen(),
        '/add-food/confirm': (context) => const ConfirmFoodItemsScreen(),
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
