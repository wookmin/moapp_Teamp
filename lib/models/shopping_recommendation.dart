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
  });

  final String name;
  final String note;
  final String tag;
  final StockStatus status;
  final String? reason;
}
