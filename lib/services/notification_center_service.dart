import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/expiry_notification.dart';
import '../models/food_item.dart';
import '../repositories/app_repositories.dart';

class NotificationCenterService extends ChangeNotifier {
  NotificationCenterService._();

  static final NotificationCenterService instance =
      NotificationCenterService._();

  static const _readKeysField = 'notificationReadKeys';
  static const _dismissedKeysField = 'notificationDismissedKeys';
  static const _maxSavedKeys = 200;

  List<ExpiryNotification> _notifications = const [];
  Set<String> _readKeys = <String>{};
  Set<String> _dismissedKeys = <String>{};
  String? _loadedUid;
  bool _isLoading = false;

  List<ExpiryNotification> get notifications => List.unmodifiable(
    _notifications.where((item) => !_dismissedKeys.contains(item.key)),
  );

  int get unreadCount =>
      notifications.where((item) => !_readKeys.contains(item.key)).length;

  bool get hasUnread => unreadCount > 0;
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadSavedState();
      final foods = await AppRepositories.expiry.fetchExpiryItems();
      _notifications = buildNotifications(foods);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    _readKeys.addAll(notifications.map((item) => item.key));
    notifyListeners();
    await _persistState();
  }

  Future<void> dismiss(String key) async {
    _dismissedKeys.add(key);
    _readKeys.add(key);
    notifyListeners();
    await _persistState();
  }

  Future<void> dismissAll() async {
    final keys = notifications.map((item) => item.key);
    _dismissedKeys.addAll(keys);
    _readKeys.addAll(keys);
    notifyListeners();
    await _persistState();
  }

  static List<ExpiryNotification> buildNotifications(List<FoodItem> foods) {
    final notifications = <ExpiryNotification>[];

    for (final food in foods) {
      final daysLeft = food.daysLeft;
      final kind = switch (daysLeft) {
        < 0 => ExpiryNotificationKind.expired,
        0 => ExpiryNotificationKind.today,
        <= 2 => ExpiryNotificationKind.soon,
        <= 5 => ExpiryNotificationKind.upcoming,
        _ => null,
      };
      if (kind == null) continue;

      notifications.add(
        ExpiryNotification(
          key: '${food.id}:${food.expiryDate.toIso8601String()}:${kind.name}',
          food: food,
          kind: kind,
        ),
      );
    }

    notifications.sort((a, b) => a.food.daysLeft.compareTo(b.food.daysLeft));
    return notifications;
  }

  Future<void> _loadSavedState() async {
    if (!AppRepositories.firebaseEnabled) {
      _loadedUid = null;
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _loadedUid == user.uid) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = snapshot.data();

    _readKeys = _stringSet(data?[_readKeysField]);
    _dismissedKeys = _stringSet(data?[_dismissedKeysField]);
    _loadedUid = user.uid;
  }

  Future<void> _persistState() async {
    if (!AppRepositories.firebaseEnabled) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      _readKeysField: _trimmed(_readKeys),
      _dismissedKeysField: _trimmed(_dismissedKeys),
    }, SetOptions(merge: true));
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! Iterable) return <String>{};
    return value.whereType<String>().toSet();
  }

  static List<String> _trimmed(Set<String> values) {
    final result = values.toList();
    if (result.length > _maxSavedKeys) {
      result.removeRange(0, result.length - _maxSavedKeys);
    }
    return result;
  }

  @visibleForTesting
  void resetForTest() {
    _notifications = const [];
    _readKeys = <String>{};
    _dismissedKeys = <String>{};
    _loadedUid = null;
    _isLoading = false;
    notifyListeners();
  }
}
