import '../../models/shopping_cart_item.dart';
import '../../models/shopping_recommendation.dart';
import '../shopping_cart_repository.dart';

class PlaceholderShoppingCartRepository implements ShoppingCartRepository {
  const PlaceholderShoppingCartRepository();

  @override
  Future<bool> addCartItemFromRecommendation(
    ShoppingRecommendation item,
  ) async => false;

  @override
  Future<int> addManyFromRecommendations(
    List<ShoppingRecommendation> items,
  ) async => 0;

  @override
  Future<void> deleteCartItem(String id) async {}

  @override
  Future<List<ShoppingCartItem>> fetchCartItems() async => const [];

  @override
  Future<void> toggleChecked(String id, bool isChecked) async {}
}
