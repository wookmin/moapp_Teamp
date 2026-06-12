import '../../models/food_item.dart';
import '../../models/shopping_recommendation.dart';
import '../shopping_recommendation_repository.dart';

class PlaceholderShoppingRecommendationRepository
    implements ShoppingRecommendationRepository {
  const PlaceholderShoppingRecommendationRepository();

  @override
  Future<List<ShoppingCategory>> fetchRecommendations({
    Set<String> foodNameHistory = const {},
    List<FoodItem> currentFoods = const [],
  }) async {
    return const [];
  }
}