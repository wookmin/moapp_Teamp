import '../models/food_item.dart';
import '../models/price_trend.dart';
import '../models/recipe.dart';

class AiRecommendationService {
  const AiRecommendationService();

  Future<Recipe?> recommendRecipe({
    required List<FoodItem> expiringFoods,
    required List<PriceTrend> priceTrends,
    required List<Recipe> recipeCandidates,
  }) async {
    return null;
  }
}
