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
  }) async {
    final trends = await _kamisPriceService.fetchPriceTrends();
    if (trends.isEmpty) return const [];

    // 사용자 냉장고 이력이 주어지면, 그 이름들과 매칭되는 품목만 추천한다.
    // 매칭은 양방향 부분일치(KAMIS 품목명에 이력 이름이 포함되거나 그 반대)로
    // 한국어 표기 차이("어린 시금치" vs "시금치" 등)를 흡수한다.
    final filteredTrends = foodNameHistory.isEmpty
        ? trends
        : trends.where((trend) {
            final itemName = trend.itemName;
            return foodNameHistory.any(
              (historyName) =>
                  itemName.contains(historyName) ||
                  historyName.contains(itemName),
            );
          }).toList();

    if (filteredTrends.isEmpty) return const [];

    final priceDropItems = filteredTrends
        .where((trend) => trend.isPriceDrop)
        .take(8)
        .map(
          (trend) => ShoppingRecommendation(
            name: trend.itemName,
            note: trend.recommendationReason,
            tag: trend.trendLabel,
            status: StockStatus.priceDrop,
            reason: 'KAMIS 최근 가격 데이터 기준',
            priceTrend: trend,
          ),
        )
        .toList();

    final watchItems = filteredTrends
        .where((trend) => !trend.isPriceDrop)
        .take(4)
        .map(
          (trend) => ShoppingRecommendation(
            name: trend.itemName,
            note: trend.recommendationReason,
            tag: trend.trendLabel,
            status: StockStatus.seasonal,
            reason: '가격 변동 확인 필요',
            priceTrend: trend,
          ),
        )
        .toList();

    return [
      if (priceDropItems.isNotEmpty)
        ShoppingCategory(
          title: '가격 기반 장보기 추천 리스트',
          neededLabel: '${priceDropItems.length}개 추천',
          items: priceDropItems,
        ),
      if (watchItems.isNotEmpty)
        ShoppingCategory(
          title: '가격 동향 확인 재료',
          neededLabel: '${watchItems.length}개',
          items: watchItems,
        ),
    ];
  }
}