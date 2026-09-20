import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);

    // درخواست پرمیشن اندروید ۱۳+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// نمایش نوتیفیکیشن فوری
  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'timelogger_channel',
      'تایم لاگر',
      channelDescription: 'اعلان‌های برنامه تایم لاگر',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details);
  }

  /// آلارم تایمر پس از X ثانیه
  static Future<void> scheduleTimerAlarm({
    required int seconds,
    required String label,
  }) async {
    await Future.delayed(Duration(seconds: seconds));
    await show(
      id: 100,
      title: '⏰ زمان تمام شد!',
      body: label,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}