import '../models/food_item.dart';
import '../models/shared_fridge.dart';
import '../models/storage_type.dart';

abstract class SharedFridgeRepository {
  Future<List<SharedFridge>> fetchMySharedFridges();

  Future<SharedFridgeInvite> createInvite({required String role});

  Future<SharedFridgeInvite> fetchInvite({
    required String ownerUid,
    required String code,
  });

  Future<SharedFridgeInvite> fetchInviteByCode(String code);

  Future<SharedFridge> acceptInvite({
    required String ownerUid,
    required String code,
  });

  Future<List<FoodItem>> fetchFoodItems(String ownerUid);

  Future<void> addFoodItem({
    required String ownerUid,
    required String name,
    required DateTime expiryDate,
    StorageType storageType = StorageType.unknown,
  });
}
