import '../models/recipe.dart';

class RecipeApiService {
  const RecipeApiService();

  Future<List<Recipe>> fetchRecipesByIngredients(
    List<String> ingredients,
  ) async {
    return const [];
  }
}
