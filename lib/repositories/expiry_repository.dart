import '../models/food_item.dart';

abstract class ExpiryRepository {
  Future<List<FoodItem>> fetchExpiryItems();
}
