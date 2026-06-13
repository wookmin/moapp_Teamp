import '../../models/food_item.dart';
import '../../models/freshness_summary.dart';
import '../../models/recipe.dart';
import '../dashboard_repository.dart';

class PlaceholderDashboardRepository implements DashboardRepository {
  const PlaceholderDashboardRepository();

  @override
  Future<FreshnessSummary> fetchFreshnessSummary() async {
    return const FreshnessSummary(score: 0, urgentCount: 0, totalCount: 0);
  }

  @override
  Stream<FreshnessSummary> watchFreshnessSummary() => const Stream.empty();

  @override
  Future<Recipe?> recommendRecipe(List<FoodItem> foods) async => null;
}
