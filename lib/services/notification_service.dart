import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum AlarmType { sound, vibrate, both }

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  NotificationDetails _detailsFor(AlarmType type) {
    final playSound = type == AlarmType.sound || type == AlarmType.both;
    final vibrate = type == AlarmType.vibrate || type == AlarmType.both;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        'time_logger_alarm',
        'Time Logger Alarm',
        channelDescription: 'Timer alarm notifications',
        importance: Importance.max,
        priority: Priority.high,
        playSound: playSound,
        enableVibration: vibrate,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        ongoing: true,
        autoCancel: false,
      ),
    );
  }

  Future<void> showAlarm({
    required int id,
    required String title,
    required String body,
    AlarmType type = AlarmType.both,
  }) async {
    await init();
    await _plugin.show(id, title, body, _detailsFor(type));
  }

  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    AlarmType type = AlarmType.both,
  }) async {
    await init();
    if (when.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      _detailsFor(type),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) async {
    await init();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }
}