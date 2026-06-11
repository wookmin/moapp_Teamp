class PriceTrend {
  const PriceTrend({
    required this.itemName,
    required this.trendLabel,
    required this.recommendationReason,
    this.unit,
    this.currentPrice,
    this.previousDayPrice,
    this.previousMonthPrice,
    this.previousYearPrice,
    this.changeRate,
    this.searchKeywords = const [],
  });

  final String itemName;
  final String trendLabel;
  final String recommendationReason;
  final String? unit;
  final int? currentPrice;
  final int? previousDayPrice;
  final int? previousMonthPrice;
  final int? previousYearPrice;
  final double? changeRate;
  final List<String> searchKeywords;

  bool get isPriceDrop => trendLabel.contains('하락');
}
