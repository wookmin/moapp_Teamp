import '../../models/food_item.dart';
import '../../models/storage_type.dart';
import '../expiry_repository.dart';

class PlaceholderExpiryRepository implements ExpiryRepository {
  const PlaceholderExpiryRepository();

  @override
  Future<List<FoodItem>> fetchExpiryItems() async => const [];

  @override
  Stream<List<FoodItem>> watchExpiryItems() => const Stream.empty();

  @override
  Future<void> addFoodItem({
    required String name,
    required DateTime expiryDate,
    String? category,
    StorageType storageType = StorageType.unknown,
  }) async {}

  @override
  Future<void> deleteFoodItem(String id) async {}
}
