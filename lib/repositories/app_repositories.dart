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
import 'placeholders/placeholder_recipe_repository.dart';
import 'profile_repository.dart';
import 'recipe_repository.dart';
import 'shopping_recommendation_repository.dart';
import 'shopping_cart_repository.dart';
import 'storage_search_repository.dart';
import 'firebase_shared_fridge_repository.dart';
import 'shared_fridge_repository.dart';

class AppRepositories {
  const AppRepositories._();

  static final AuthRepository auth = FirebaseAuthRepository();
  static final ExpiryRepository expiry = FirebaseExpiryRepository();
  static final DashboardRepository dashboard = FirebaseDashboardRepository();
  static final ProfileRepository profile = FirebaseProfileRepository();
  static final CommunityRepository community = FirebaseCommunityRepository();
  static final StorageSearchRepository storageSearch =
      FirebaseStorageSearchRepository();
  static final ShoppingRecommendationRepository shoppingRecommendations =
      KamisShoppingRecommendationRepository();
  static final ShoppingCartRepository shoppingCart =
      FirebaseShoppingCartRepository();
  static final SharedFridgeRepository sharedFridges =
      FirebaseSharedFridgeRepository();
  static const RecipeRepository recipes = PlaceholderRecipeRepository();
}
