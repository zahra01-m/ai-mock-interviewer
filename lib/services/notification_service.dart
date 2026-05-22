import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<void> showPracticeReminder() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminder', 'Daily Practice',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      0,
      'Time to Practice! 🎯',
      'Complete today\'s mock interview and keep your streak alive!',
      details,
    );
  }

  static Future<void> cancelAll() async => await _plugin.cancelAll();
}