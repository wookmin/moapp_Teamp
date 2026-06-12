import '../../models/food_item.dart';
import '../../models/shared_fridge.dart';
import '../../models/storage_type.dart';
import '../shared_fridge_repository.dart';

class PlaceholderSharedFridgeRepository implements SharedFridgeRepository {
  const PlaceholderSharedFridgeRepository();

  @override
  Future<SharedFridge> acceptInvite({
    required String ownerUid,
    required String code,
  }) {
    throw UnsupportedError('공유 냉장고는 모바일 앱에서 사용할 수 있어요.');
  }

  @override
  Future<void> addFoodItem({
    required String ownerUid,
    required String name,
    required DateTime expiryDate,
    StorageType storageType = StorageType.unknown,
  }) async {}

  @override
  Future<SharedFridgeInvite> createInvite({required String role}) {
    throw UnsupportedError('공유 냉장고는 모바일 앱에서 사용할 수 있어요.');
  }

  @override
  Future<SharedFridgeInvite> fetchInvite({
    required String ownerUid,
    required String code,
  }) {
    throw UnsupportedError('공유 냉장고는 모바일 앱에서 사용할 수 있어요.');
  }

  @override
  Future<SharedFridgeInvite> fetchInviteByCode(String code) {
    throw UnsupportedError('공유 냉장고는 모바일 앱에서 사용할 수 있어요.');
  }

  @override
  Future<List<FoodItem>> fetchFoodItems(String ownerUid) async => const [];

  @override
  Future<List<SharedFridge>> fetchMySharedFridges() async => const [];
}
