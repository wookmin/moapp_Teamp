import '../models/food_item.dart';
import '../models/shopping_recommendation.dart';
import '../services/kamis_price_service.dart';
import 'shopping_recommendation_repository.dart';

class KamisShoppingRecommendationRepository
    implements ShoppingRecommendationRepository {
  KamisShoppingRecommendationRepository({KamisPriceService? kamisPriceService})
    : _kamisPriceService = kamisPriceService ?? KamisPriceService();

  final KamisPriceService _kamisPriceService;

  @override
  Future<List<ShoppingCategory>> fetchRecommendations({
    Set<String> foodNameHistory = const {},
    List<FoodItem> currentFoods = const [],
  }) async {
    final categories = <ShoppingCategory>[];

    // ── 카테고리 1: 곧 교체가 필요해요 ──
    // 유통기한 3일 이내 → 새로 구매 추천
    final urgentFoods = currentFoods
        .where((f) => f.daysLeft <= 3)
        .toList()
      ..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    if (urgentFoods.isNotEmpty) {
      categories.add(ShoppingCategory(
        title: '곧 교체가 필요해요',
        neededLabel: '${urgentFoods.length}개 임박',
        items: urgentFoods.map((f) {
          final label = f.daysLeft < 0
              ? '유통기한 ${-f.daysLeft}일 초과'
              : f.daysLeft == 0
                  ? '오늘 만료'
                  : '${f.daysLeft}일 후 만료';
          return ShoppingRecommendation(
            name: f.name,
            note: '$label — 새로 구매하세요',
            tag: f.statusLabel,
            status: StockStatus.out,
            reason: '냉장고 유통기한 기반 추천',
          );
        }).toList(),
      ));
    }

    // ── KAMIS 가격 데이터 조회 ──
    final trends = await _kamisPriceService.fetchPriceTrends();

    if (trends.isNotEmpty && foodNameHistory.isNotEmpty) {
      // 사용자 냉장고 이력과 매칭
      final matchedTrends = trends.where((trend) {
        final itemName = trend.itemName;
        return foodNameHistory.any(
          (historyName) =>
              itemName.contains(historyName) ||
              historyName.contains(itemName),
        );
      }).toList();

      // ── 카테고리 2: 지금 사면 이득이에요 ──
      // 가격 하락 중 + 내 냉장고 이력 매칭
      final priceDropItems = matchedTrends
          .where((trend) => trend.isPriceDrop)
          .take(6)
          .map((trend) => ShoppingRecommendation(
                name: trend.itemName,
                note: trend.recommendationReason,
                tag: trend.trendLabel,
                status: StockStatus.priceDrop,
                reason: '가격 하락 중 — 지금 사면 좋아요',
                priceTrend: trend,
              ))
          .toList();

      if (priceDropItems.isNotEmpty) {
        categories.add(ShoppingCategory(
          title: '지금 사면 이득이에요',
          neededLabel: '${priceDropItems.length}개 추천',
          items: priceDropItems,
        ));
      }

      // ── 카테고리 3: 이런 건 어때요? ──
      // 매칭됐지만 가격 하락은 아닌 품목 (참고용)
      final watchItems = matchedTrends
          .where((trend) => !trend.isPriceDrop)
          .take(4)
          .map((trend) => ShoppingRecommendation(
                name: trend.itemName,
                note: trend.recommendationReason,
                tag: trend.trendLabel,
                status: StockStatus.seasonal,
                reason: '냉장고 이력 기반 추천',
                priceTrend: trend,
              ))
          .toList();

      if (watchItems.isNotEmpty) {
        categories.add(ShoppingCategory(
          title: '이런 건 어때요?',
          neededLabel: '${watchItems.length}개',
          items: watchItems,
        ));
      }
    }

    return categories;
  }
}