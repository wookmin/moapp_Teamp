import '../../models/food_item.dart';
import '../expiry_repository.dart';

class PlaceholderExpiryRepository implements ExpiryRepository {
  const PlaceholderExpiryRepository();

  @override
  Future<List<FoodItem>> fetchExpiryItems() async {
    return const [];
  }
}
