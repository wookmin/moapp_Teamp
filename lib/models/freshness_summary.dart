import 'food_item.dart';
import 'recipe.dart';

class FreshnessSummary {
  const FreshnessSummary({
    required this.score,
    required this.urgentCount,
    this.urgentFoods = const [],
    this.recommendedRecipe,
  });

  final int score;
  final int urgentCount;
  final List<FoodItem> urgentFoods;
  final Recipe? recommendedRecipe;

  bool get hasConnectedData =>
      score > 0 ||
      urgentCount > 0 ||
      urgentFoods.isNotEmpty ||
      recommendedRecipe != null;
}
