import 'auth_repository.dart';
import 'community_repository.dart';
import 'dashboard_repository.dart';
import 'expiry_repository.dart';
import 'firebase_auth_repository.dart';
import 'firebase_community_repository.dart';
import 'firebase_dashboard_repository.dart';
import 'firebase_expiry_repository.dart';
import 'firebase_profile_repository.dart';
import 'firebase_shopping_cart_repository.dart';
import 'firebase_storage_search_repository.dart';
import 'kamis_shopping_recommendation_repository.dart';
import 'placeholders/placeholder_auth_repository.dart';
import 'placeholders/placeholder_community_repository.dart';
import 'placeholders/placeholder_dashboard_repository.dart';
import 'placeholders/placeholder_expiry_repository.dart';
import 'placeholders/placeholder_profile_repository.dart';
import 'placeholders/placeholder_recipe_repository.dart';
import 'placeholders/placeholder_shared_fridge_repository.dart';
import 'placeholders/placeholder_shopping_cart_repository.dart';
import 'placeholders/placeholder_shopping_recommendation_repository.dart';
import 'placeholders/placeholder_storage_search_repository.dart';
import 'profile_repository.dart';
import 'recipe_repository.dart';
import 'shopping_recommendation_repository.dart';
import 'shopping_cart_repository.dart';
import 'storage_search_repository.dart';
import 'firebase_shared_fridge_repository.dart';
import 'shared_fridge_repository.dart';

class AppRepositories {
  const AppRepositories._();

  static bool _firebaseEnabled = true;

  static bool get firebaseEnabled => _firebaseEnabled;

  static void configure({required bool firebaseEnabled}) {
    _firebaseEnabled = firebaseEnabled;
  }

  static AuthRepository get auth => _firebaseEnabled
      ? FirebaseAuthRepository()
      : const PlaceholderAuthRepository();
  static ExpiryRepository get expiry => _firebaseEnabled
      ? FirebaseExpiryRepository()
      : const PlaceholderExpiryRepository();
  static DashboardRepository get dashboard => _firebaseEnabled
      ? FirebaseDashboardRepository()
      : const PlaceholderDashboardRepository();
  static ProfileRepository get profile => _firebaseEnabled
      ? FirebaseProfileRepository()
      : const PlaceholderProfileRepository();
  static CommunityRepository get community => _firebaseEnabled
      ? FirebaseCommunityRepository()
      : const PlaceholderCommunityRepository();
  static StorageSearchRepository get storageSearch => _firebaseEnabled
      ? FirebaseStorageSearchRepository()
      : const PlaceholderStorageSearchRepository();
  static ShoppingRecommendationRepository get shoppingRecommendations =>
      _firebaseEnabled
      ? KamisShoppingRecommendationRepository()
      : const PlaceholderShoppingRecommendationRepository();
  static ShoppingCartRepository get shoppingCart => _firebaseEnabled
      ? FirebaseShoppingCartRepository()
      : const PlaceholderShoppingCartRepository();
  static SharedFridgeRepository get sharedFridges => _firebaseEnabled
      ? FirebaseSharedFridgeRepository()
      : const PlaceholderSharedFridgeRepository();
  static const RecipeRepository recipes = PlaceholderRecipeRepository();
}
