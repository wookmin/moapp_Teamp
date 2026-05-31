import '../models/food_item.dart';

abstract class ExpiryRepository {
  Future<List<FoodItem>> fetchExpiryItems();
  Future<void> addFoodItem({required String name, required DateTime expiryDate});
  Future<void> deleteFoodItem(String id);
}
