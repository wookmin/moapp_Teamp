import 'food_item.dart';
import 'recipe.dart';

class FreshnessSummary {
  const FreshnessSummary({
    required this.score,
    required this.urgentCount,
    required this.totalCount,
    this.urgentFoods = const [],
    this.recommendedRecipe,
    this.recipeError,
  });

  final int score;
  final int urgentCount;
  final int totalCount;
  final List<FoodItem> urgentFoods;
  final Recipe? recommendedRecipe;
  final String? recipeError;

  bool get hasConnectedData => totalCount > 0;
}
