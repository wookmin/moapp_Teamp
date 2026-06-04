import '../models/shopping_recommendation.dart';

abstract class ShoppingRecommendationRepository {
  /// 장보기 추천을 가져온다.
  ///
  /// [foodNameHistory]가 비어있지 않으면, 그 이름과 매칭되는 품목만 반환한다.
  /// (사용자가 현재 냉장고에 가지고 있거나, 한 번이라도 등록한 적 있는 품목들)
  Future<List<ShoppingCategory>> fetchRecommendations({
    Set<String> foodNameHistory = const {},
  });
}