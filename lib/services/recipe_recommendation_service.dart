import 'package:flutter/foundation.dart';

import '../models/food_item.dart';
import '../models/price_trend.dart';
import '../models/recipe.dart';
import 'ai_recommendation_service.dart';
import 'kamis_price_service.dart';
import 'recipe_api_service.dart';

class RecipeRecommendationService {
  RecipeRecommendationService({
    RecipeApiService? recipeApiService,
    KamisPriceService? kamisPriceService,
    AiRecommendationService? aiService,
  }) : _recipeApiService = recipeApiService ?? RecipeApiService(),
       _kamisPriceService = kamisPriceService ?? const KamisPriceService(),
       _aiService = aiService ?? AiRecommendationService();

  final RecipeApiService _recipeApiService;
  final KamisPriceService _kamisPriceService;
  final AiRecommendationService _aiService;

  Future<Recipe?> recommendRecipe({required List<FoodItem> foods}) async {
    if (foods.isEmpty) {
      return null;
    }

    final prioritizedFoods = _prioritizeFoods(foods);
    final ingredientNames = prioritizedFoods.map((food) => food.name).toList();
    final recipeCandidates = await _recipeApiService.fetchRecipesByIngredients(
      ingredientNames,
    );
    final priceTrends = await _kamisPriceService.fetchPriceTrends();
    final rankedRecipes = _rankRecipes(
      recipeCandidates: recipeCandidates,
      foods: prioritizedFoods,
      priceTrends: priceTrends,
    );

    if (rankedRecipes.isEmpty) {
      return null;
    }

    return _aiService.recommendRecipe(
      expiringFoods: prioritizedFoods,
      recipeCandidates: rankedRecipes.take(5).toList(),
      priceTrends: priceTrends,
    );
  }

  List<FoodItem> _prioritizeFoods(List<FoodItem> foods) {
    final sorted = [...foods]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return sorted.take(8).toList();
  }

  List<Recipe> _rankRecipes({
    required List<Recipe> recipeCandidates,
    required List<FoodItem> foods,
    required List<PriceTrend> priceTrends,
  }) {
    final scoredRecipes =
        recipeCandidates
            .map(
              (recipe) => MapEntry(
                recipe,
                _scoreRecipe(
                  recipe: recipe,
                  foods: foods,
                  priceTrends: priceTrends,
                ),
              ),
            )
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return scoredRecipes.map((entry) => entry.key).toList();
  }

  int _scoreRecipe({
    required Recipe recipe,
    required List<FoodItem> foods,
    required List<PriceTrend> priceTrends,
  }) {
    final recipeText = [
      recipe.title,
      recipe.summary,
      recipe.ingredients.join(' '),
      recipe.category,
      recipe.cookingMethod,
    ].whereType<String>().join(' ');

    var score = 0;

    for (final food in foods) {
      if (recipeText.contains(food.name)) {
        score += food.isUrgent ? 40 : 24;
        if (food.daysLeft <= 0) {
          score += 12;
        }
      }
    }

    for (final trend in priceTrends) {
      if (recipeText.contains(trend.itemName)) {
        score += 12;
      }
    }

    if ((recipe.sodium ?? 0) > 0 && (recipe.sodium ?? 0) <= 800) {
      score += 4;
    }

    if (recipe.steps.length <= 8) {
      score += 4;
    }

    return score;
  }
}
