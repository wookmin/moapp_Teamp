import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';

import '../models/food_item.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _pluginUnavailable = false;

  Future<void> initialize() async {
    if (_initialized || _pluginUnavailable) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('notification payload: ${response.payload}');
        },
      );
      _initialized = true;
    } on MissingPluginException catch (error) {
      _pluginUnavailable = true;
      debugPrint('Local notifications plugin is unavailable: $error');
    }
  }

  Future<bool> requestPermissions() async {
    await initialize();
    if (_pluginUnavailable) return false;

    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final macGranted = await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    return androidGranted ?? iosGranted ?? macGranted ?? true;
  }

  Future<int> showTodayExpiryAlerts(List<FoodItem> foods) async {
    await initialize();
    if (_pluginUnavailable) return 0;

    final todayFoods = foods
        .where((food) => _isSameDate(food.expiryDate, DateTime.now()))
        .toList();

    if (todayFoods.isEmpty) {
      return 0;
    }

    final firstFoodName = todayFoods.first.name;
    final title = todayFoods.length == 1
        ? '$firstFoodName가 곧 상할 수 있어요'
        : '$firstFoodName 외 ${todayFoods.length - 1}개가 곧 상할 수 있어요';

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: '오늘까지 먹으면 좋아요. 냉장고를 확인해보세요.',
      notificationDetails: _notificationDetails(),
      payload: 'today_expiry',
    );

    return todayFoods.length;
  }


  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'expiry_alerts',
        '유통기한 알림',
        channelDescription: '오늘 소비해야 할 식재료를 알려줍니다.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
