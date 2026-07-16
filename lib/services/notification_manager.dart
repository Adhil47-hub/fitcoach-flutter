import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'fitcoach_channel',
        'FitCoach Notifications',
        channelDescription: 'Main channel for FitCoach alerts',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFD0FD3E),
      ),
    );
  }

  Future<void> _saveToInbox(String title, String body, String type) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('notifications').insert({
          'user_id': user.id,
          'title': title,
          'body': body,
          'type': type,
        });
      } catch (e) {
        debugPrint("Error saving to inbox: $e");
      }
    }
  }

  Future<void> scheduleWorkoutReminder() async {
    await _notificationsPlugin.zonedSchedule(
      id: 201,
      title: 'Time to train! 🏋️‍♂️',
      body: 'Your daily workout is waiting. Let\'s get after it today!',
      scheduledDate: _nextInstanceOfTime(7, 0),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleMealReminders() async {
    await _notificationsPlugin.zonedSchedule(
      id: 101,
      title: 'Fuel Up! 🍳',
      body: 'Time for breakfast. Start your day with solid protein.',
      scheduledDate: _nextInstanceOfTime(8, 0),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    await _notificationsPlugin.zonedSchedule(
      id: 102,
      title: 'Lunch Time 🥗',
      body: 'Keep your energy up! Time to grab a healthy lunch.',
      scheduledDate: _nextInstanceOfTime(13, 0),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    await _notificationsPlugin.zonedSchedule(
      id: 103,
      title: 'Dinner & Recover 🥩',
      body: 'Last big meal of the day. Fuel your recovery!',
      scheduledDate: _nextInstanceOfTime(19, 0),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleInactivityNudge() async {
    await cancelNotification(701);

    final tz.TZDateTime threeDaysFromNow = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(days: 3));

    await _notificationsPlugin.zonedSchedule(
      id: 701,
      title: 'We miss you! 👀',
      body:
          'Rest days are crucial, but it\'s been 3 days. Ready to hit the iron?',
      scheduledDate: threeDaysFromNow,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> firePRCelebration(String exercise, String weight) async {
    String title = 'New Personal Record! 🏆';
    String body =
        'Incredible work! You just hit a new PR on $exercise ($weight).';
    await _notificationsPlugin.show(
      id: 801,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
    await _saveToInbox(title, body, 'milestone');
  }

  Future<void> checkWaterGoal(double currentLiters, double goalLiters) async {
    if (currentLiters >= goalLiters) {
      String title = 'Hydration Goal Met! 💧';
      String body = 'Awesome job hitting your daily water target.';
      await _notificationsPlugin.show(
        id: 301,
        title: title,
        body: body,
        notificationDetails: _notificationDetails(),
      );
      await _saveToInbox(title, body, 'goal');
    }
  }

  Future<void> sendTestNotification() async {
    await _notificationsPlugin.show(
      id: 999,
      title: 'Test ✅',
      body: 'Notifications are working perfectly!',
      notificationDetails: _notificationDetails(),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDay(int weekday, int hour) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, 0);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
