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
import 'screens/storage_search/storage_rulebook_screen.dart';
import 'screens/shopping_recommendations/shopping_recommendations_screen.dart';
import 'screens/storage_search/storage_search_screen.dart';
import 'services/firebase_bootstrap.dart';
import 'services/notification_service.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await FirebaseBootstrap.initialize();
  // 로컬 알림 기능
  await NotificationService.instance.initialize();
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
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<void> _onGenerateRoute(RouteSettings settings) {
    final builder = switch (settings.name) {
      '/' => (_) => const AuthGate(),
      '/login' => (_) => const LoginScreen(),
      '/add-food' => (_) => const FoodAddMethodScreen(),
      '/add-food/manual' => (_) => const ManualFoodAddScreen(),
      '/add-food/confirm' => (_) => const ConfirmFoodItemsScreen(),
      '/expiry-management' => (_) => const ExpiryManagementScreen(),
      '/profile' => (_) => const ProfileScreen(),
      '/shopping-recommendations' =>
        (_) => const ShoppingRecommendationsScreen(),
      '/storage-search' => (_) => const StorageSearchScreen(),
      '/storage-rulebook' => (_) => const StorageRulebookScreen(),
      '/community' => (_) => const CommunityScreen(),
      _ => (_) => const AuthGate(),
    };

    final routeName = settings.name ?? '/';
    final shouldSkipTransition = {
      '/',
      '/storage-search',
      '/community',
      '/shopping-recommendations',
      '/profile',
      '/expiry-management',
    }.contains(routeName);

    if (shouldSkipTransition) {
      return PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }
}
