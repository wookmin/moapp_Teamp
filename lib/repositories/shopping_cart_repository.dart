import '../models/shopping_cart_item.dart';
import '../models/shopping_recommendation.dart';

abstract class ShoppingCartRepository {
  Future<List<ShoppingCartItem>> fetchCartItems();

  Future<bool> addCartItemFromRecommendation(ShoppingRecommendation item);

  Future<int> addManyFromRecommendations(List<ShoppingRecommendation> items);

  Future<void> toggleChecked(String id, bool isChecked);

  Future<void> deleteCartItem(String id);
}
