import '../models/food_item.dart';
import '../models/storage_type.dart';

abstract class ExpiryRepository {
  Future<List<FoodItem>> fetchExpiryItems();
  Future<void> addFoodItem({
    required String name,
    required DateTime expiryDate,
    String? category,
    StorageType storageType = StorageType.unknown,
  });
  Future<void> deleteFoodItem(String id);
}
