import '../models/shopping_recommendation.dart';

abstract class ShoppingRecommendationRepository {
  Future<List<ShoppingCategory>> fetchRecommendations();
}
