import 'food_item.dart';

enum ExpiryNotificationKind { expired, today, soon, upcoming }

class ExpiryNotification {
  const ExpiryNotification({
    required this.key,
    required this.food,
    required this.kind,
  });

  final String key;
  final FoodItem food;
  final ExpiryNotificationKind kind;

  bool get isUrgent =>
      kind == ExpiryNotificationKind.expired ||
      kind == ExpiryNotificationKind.today;
}
