import '../models/food_item.dart';
import '../models/shopping_recommendation.dart';

abstract class ShoppingRecommendationRepository {
  /// 장보기 추천을 가져온다.
  ///
  /// [foodNameHistory] — 사용자가 냉장고에 등록한 적 있는 품목 이름 셋
  /// [currentFoods] — 현재 냉장고에 있는 FoodItem 목록 (유통기한 기반 추천에 사용)
  Future<List<ShoppingCategory>> fetchRecommendations({
    Set<String> foodNameHistory = const {},
    List<FoodItem> currentFoods = const [],
  });
}