import '../models/food_item.dart';

abstract final class FreshnessCalculator {
  static int calculate(List<FoodItem> foods) {
    if (foods.isEmpty) return 0;

    final freshCount = foods.where((food) => !food.isUrgent).length;
    return ((freshCount / foods.length) * 100).round();
  }
}
