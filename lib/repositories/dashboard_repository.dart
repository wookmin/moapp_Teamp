import '../models/food_item.dart';
import '../models/freshness_summary.dart';
import '../models/recipe.dart';

abstract class DashboardRepository {
  Future<FreshnessSummary> fetchFreshnessSummary();

  Future<Recipe?> recommendRecipe(List<FoodItem> foods);
}
