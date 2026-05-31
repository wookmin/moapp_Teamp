import '../models/freshness_summary.dart';
import '../models/recipe.dart';
import '../services/recipe_recommendation_service.dart';
import 'dashboard_repository.dart';
import 'firebase_expiry_repository.dart';

class FirebaseDashboardRepository implements DashboardRepository {
  FirebaseDashboardRepository({
    FirebaseExpiryRepository? expiryRepository,
    RecipeRecommendationService? recommendationService,
  }) : _expiryRepository = expiryRepository ?? FirebaseExpiryRepository(),
       _recommendationService =
           recommendationService ?? RecipeRecommendationService();

  final FirebaseExpiryRepository _expiryRepository;
  final RecipeRecommendationService _recommendationService;

  @override
  Future<FreshnessSummary> fetchFreshnessSummary() async {
    final items = await _expiryRepository.fetchExpiryItems();

    if (items.isEmpty) {
      return const FreshnessSummary(score: 0, urgentCount: 0, totalCount: 0);
    }

    final urgentFoods = items.where((f) => f.isUrgent).toList();
    final freshCount = items.where((f) => f.daysLeft > 7).length;
    final score = ((freshCount / items.length) * 100).round();

    String? recipeError;
    Recipe? recipe;
    try {
      recipe = await _recommendationService.recommendRecipe(foods: items);
    } catch (e) {
      recipeError = e.toString();
    }

    return FreshnessSummary(
      score: score,
      urgentCount: urgentFoods.length,
      totalCount: items.length,
      urgentFoods: urgentFoods,
      recommendedRecipe: recipe,
      recipeError: recipeError,
    );
  }
}
