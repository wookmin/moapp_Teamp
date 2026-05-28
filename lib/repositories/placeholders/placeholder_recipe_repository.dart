import '../../models/recipe.dart';
import '../recipe_repository.dart';

class PlaceholderRecipeRepository implements RecipeRepository {
  const PlaceholderRecipeRepository();

  @override
  Future<List<Recipe>> fetchRecipesByIngredients(
    List<String> ingredients,
  ) async {
    return const [];
  }
}
