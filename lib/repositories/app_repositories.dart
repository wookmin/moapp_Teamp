import 'auth_repository.dart';
import 'community_repository.dart';
import 'dashboard_repository.dart';
import 'expiry_repository.dart';
import 'firebase_auth_repository.dart';
import 'placeholders/placeholder_community_repository.dart';
import 'placeholders/placeholder_dashboard_repository.dart';
import 'placeholders/placeholder_expiry_repository.dart';
import 'placeholders/placeholder_profile_repository.dart';
import 'placeholders/placeholder_recipe_repository.dart';
import 'placeholders/placeholder_shopping_recommendation_repository.dart';
import 'placeholders/placeholder_storage_search_repository.dart';
import 'profile_repository.dart';
import 'recipe_repository.dart';
import 'shopping_recommendation_repository.dart';
import 'storage_search_repository.dart';

class AppRepositories {
  const AppRepositories._();

  static final AuthRepository auth = FirebaseAuthRepository();
  static const DashboardRepository dashboard = PlaceholderDashboardRepository();
  static const StorageSearchRepository storageSearch =
      PlaceholderStorageSearchRepository();
  static const CommunityRepository community = PlaceholderCommunityRepository();
  static const ShoppingRecommendationRepository shoppingRecommendations =
      PlaceholderShoppingRecommendationRepository();
  static const ExpiryRepository expiry = PlaceholderExpiryRepository();
  static const ProfileRepository profile = PlaceholderProfileRepository();
  static const RecipeRepository recipes = PlaceholderRecipeRepository();
}
