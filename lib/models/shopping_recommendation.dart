import 'price_trend.dart';

enum StockStatus { out, low, seasonal, priceDrop }

class ShoppingCategory {
  const ShoppingCategory({
    required this.title,
    required this.neededLabel,
    this.items = const [],
  });

  final String title;
  final String neededLabel;
  final List<ShoppingRecommendation> items;
}

class ShoppingRecommendation {
  const ShoppingRecommendation({
    required this.name,
    required this.note,
    required this.tag,
    required this.status,
    this.reason,
    this.imageUrl,
    this.priceTrend,
  });

  final String name;
  final String note;
  final String tag;
  final StockStatus status;
  final String? reason;

  /// foodCatalog에서 가져온 상품 이미지 URL. null이면 placeholder 표시.
  final String? imageUrl;

  /// KAMIS 가격 동향. 있으면 카드 하단에 매수 추천 메시지가 표시됨.
  final PriceTrend? priceTrend;
}