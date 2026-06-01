import '../models/shopping_recommendation.dart';
import '../services/kamis_price_service.dart';
import 'shopping_recommendation_repository.dart';

class KamisShoppingRecommendationRepository
    implements ShoppingRecommendationRepository {
  KamisShoppingRecommendationRepository({KamisPriceService? kamisPriceService})
    : _kamisPriceService = kamisPriceService ?? KamisPriceService();

  final KamisPriceService _kamisPriceService;

  @override
  Future<List<ShoppingCategory>> fetchRecommendations() async {
    final trends = await _kamisPriceService.fetchPriceTrends();
    if (trends.isEmpty) return const [];

    final priceDropItems = trends
        .where((trend) => trend.isPriceDrop)
        .take(8)
        .map(
          (trend) => ShoppingRecommendation(
            name: trend.itemName,
            note: trend.recommendationReason,
            tag: trend.trendLabel,
            status: StockStatus.priceDrop,
            reason: 'KAMIS 최근 가격 데이터 기준',
          ),
        )
        .toList();
    final watchItems = trends
        .where((trend) => !trend.isPriceDrop)
        .take(4)
        .map(
          (trend) => ShoppingRecommendation(
            name: trend.itemName,
            note: trend.recommendationReason,
            tag: trend.trendLabel,
            status: StockStatus.seasonal,
            reason: '가격 변동 확인 필요',
          ),
        )
        .toList();

    return [
      if (priceDropItems.isNotEmpty)
        ShoppingCategory(
          title: '오늘 가격이 내려간 재료',
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
