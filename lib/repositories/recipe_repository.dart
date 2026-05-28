import '../models/recipe.dart';

abstract class RecipeRepository {
  Future<List<Recipe>> fetchRecipesByIngredients(List<String> ingredients);
}
