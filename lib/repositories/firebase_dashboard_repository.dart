import '../models/food_item.dart';
import '../models/freshness_summary.dart';
import '../models/recipe.dart';
import '../services/recipe_recommendation_service.dart';
import 'dashboard_repository.dart';
import 'firebase_expiry_repository.dart';

class FirebaseDashboardRepository implements DashboardRepository {
  FirebaseDashboardRepository({
    FirebaseExpiryRepository? expiryRepository,
    RecipeRecommendationService? recipeService,
  }) : _expiryRepository = expiryRepository ?? FirebaseExpiryRepository(),
       _recipeService = recipeService ?? RecipeRecommendationService();

  final FirebaseExpiryRepository _expiryRepository;
  final RecipeRecommendationService _recipeService;

  @override
  Future<FreshnessSummary> fetchFreshnessSummary() async {
    // ── 1단계: 냉장고 식재료 가져오기 ──
    List<FoodItem> items;
    try {
      items = await _expiryRepository.fetchExpiryItems();
    } catch (_) {
      // 식재료 조회 실패 → 빈 상태 반환 (레시피도 불가)
      return const FreshnessSummary(score: 0, urgentCount: 0, totalCount: 0);
    }

    if (items.isEmpty) {
      return const FreshnessSummary(score: 0, urgentCount: 0, totalCount: 0);
    }

    // ── 2단계: 신선도 점수 계산 (즉시, API 없음) ──
    final urgentFoods = items.where((f) => f.isUrgent).toList();
    final freshCount = items.where((f) => f.daysLeft > 7).length;
    final score = ((freshCount / items.length) * 100).round();

    return FreshnessSummary(
      score: score,
      urgentCount: urgentFoods.length,
      totalCount: items.length,
      foods: items,
      urgentFoods: urgentFoods,
    );
  }

  @override
  Future<Recipe?> recommendRecipe(List<FoodItem> foods) {
    return _recipeService.recommendRecipe(foods: foods);
  }
}
