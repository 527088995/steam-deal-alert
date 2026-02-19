import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../app.dart';
import '../screens/detail_screen.dart';
import 'constants.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const int _daily9AmId = 88888;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    await _createPriceAlertChannel();
    try {
      tz_data.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('America/New_York'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    } catch (_) {}
    await _scheduleDaily9Am();
  }

  /// 创建 price_alert channel（闭环：安装 → 请求权限 → 创建 Channel → 后台发通知）
  Future<void> _createPriceAlertChannel() async {
    try {
      const channel = AndroidNotificationChannel(
        'price_alert',
        'Price Alerts',
        description: 'Wishlist price drop alerts',
        importance: Importance.max,
        playSound: true,
      );
      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      debugPrint('createPriceAlertChannel: $e');
    }
  }

  /// 每日 9:00 本地时间推送「今日折扣」提醒
  Future<void> _scheduleDaily9Am() async {
    try {
      await notificationsPlugin.cancel(_daily9AmId);
      final now = tz.TZDateTime.now(tz.local);
      var next9 = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
      if (next9.isBefore(now)) next9 = next9.add(const Duration(days: 1));
      const androidDetails = AndroidNotificationDetails(
        'daily_channel',
        'Daily Deals',
        channelDescription: 'Daily Steam deal reminder',
        importance: Importance.high,
        priority: Priority.high,
      );
      await notificationsPlugin.zonedSchedule(
        _daily9AmId,
        '🔥 New Steam Deals!',
        'Check today\'s hottest discounts now!',
        next9,
        NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDaily9Am: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final nav = navigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil('/main', (route) => false);
    // Top 5 点击只打开首页列表，不进入详情
    if (payload == AppConstants.payloadTop5) return;
    nav.push(MaterialPageRoute(
      builder: (_) => DetailScreen(appId: payload),
    ));
  }

  /// 价格提醒专用 channel（与 _createPriceAlertChannel 一致，importance.max）
  static const AndroidNotificationDetails priceAlertChannel = AndroidNotificationDetails(
    'price_alert',
    'Price Alerts',
    channelDescription: 'Wishlist price drop alerts',
    importance: Importance.max,
    priority: Priority.high,
  );

  Future<void> showNotification(
    String title,
    String body, {
    int? notificationId,
    String? payload,
    bool usePriceAlertChannel = false,
  }) async {
    final androidDetails = usePriceAlertChannel
        ? priceAlertChannel
        : const AndroidNotificationDetails(
            'deal_channel',
            'Deals',
            channelDescription: 'Steam deal alerts',
            importance: Importance.high,
            priority: Priority.high,
          );

    final details = NotificationDetails(android: androidDetails);

    final id = notificationId ?? (DateTime.now().millisecondsSinceEpoch % 100000);
    await notificationsPlugin.show(id, title, body, details, payload: payload);
  }
}
