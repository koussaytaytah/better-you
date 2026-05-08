import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../shared/models/notification_settings_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click if needed
      },
    );
  }

  Future<void> scheduleDailyReminder() async {
    if (kIsWeb) return;

    await _notificationsPlugin.zonedSchedule(
      0,
      'You are missing an XP boost! 🏆',
      'Drink some water and finish your quests before the day ends! 💧',
      _nextInstanceOf8PM(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminders',
          channelDescription: 'Reminders to log daily health data',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOf8PM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      20, // 8 PM
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // ==================== SMART NOTIFICATION SYSTEM ====================

  // Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancelAll();
  }

  // Cancel specific notification by ID
  Future<void> cancelNotification(int id) async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(id);
  }

  // Schedule all notifications based on user settings
  Future<void> scheduleAllNotifications(NotificationSettings settings) async {
    if (kIsWeb) return;
    
    await cancelAllNotifications();
    
    if (settings.mealRemindersEnabled) {
      await _scheduleMealReminders(settings);
    }
    
    if (settings.waterRemindersEnabled) {
      await _scheduleWaterReminders(settings);
    }
    
    if (settings.streakRemindersEnabled) {
      await _scheduleStreakReminders(settings);
    }
    
    if (settings.weeklyDigestEnabled) {
      await _scheduleWeeklyDigest(settings);
    }
    
    if (settings.mealPlanRemindersEnabled) {
      await _scheduleMealPlanReminders(settings);
    }
    
    if (settings.smartCoachEnabled) {
      await _scheduleSmartCoach(settings);
    }
  }

  // ==================== MEAL REMINDERS ====================
  
  Future<void> _scheduleMealReminders(NotificationSettings settings) async {
    // Breakfast reminder
    await _scheduleDailyNotification(
      id: 100,
      title: '🍳 Breakfast Time!',
      body: 'Start your day with a healthy meal. Log your breakfast to keep your streak going!',
      hour: settings.breakfastReminderHour,
      minute: settings.breakfastReminderMinute,
      channelId: 'meal_reminders',
      channelName: 'Meal Reminders',
    );
    
    // Lunch reminder
    await _scheduleDailyNotification(
      id: 101,
      title: '🥗 Lunch Break!',
      body: 'Fuel up with a nutritious lunch. What are you having today?',
      hour: settings.lunchReminderHour,
      minute: settings.lunchReminderMinute,
      channelId: 'meal_reminders',
      channelName: 'Meal Reminders',
    );
    
    // Dinner reminder
    await _scheduleDailyNotification(
      id: 102,
      title: '🍽️ Dinner Time!',
      body: 'Wind down with a healthy dinner. Track your last meal of the day!',
      hour: settings.dinnerReminderHour,
      minute: settings.dinnerReminderMinute,
      channelId: 'meal_reminders',
      channelName: 'Meal Reminders',
    );
  }

  // ==================== WATER REMINDERS ====================
  
  Future<void> _scheduleWaterReminders(NotificationSettings settings) async {
    final interval = settings.waterReminderIntervalHours;
    final now = tz.TZDateTime.now(tz.local);
    
    // Schedule water reminders throughout the day (8am to 8pm)
    var currentTime = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, 8, 0,
    );
    
    int notificationId = 200;
    
    while (currentTime.hour < 20) {
      if (currentTime.isAfter(now)) {
        final glassesRemaining = settings.dailyWaterGoal - ((currentTime.hour - 8) ~/ interval);
        final body = glassesRemaining > 0
            ? '💧 Hydrate! $glassesRemaining glasses left to reach your goal.'
            : '💧 Great job! You\'ve hit your water goal for today!';
        
        await _notificationsPlugin.zonedSchedule(
          notificationId++,
          'Water Reminder 💧',
          body,
          currentTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'water_reminders',
              'Water Reminders',
              channelDescription: 'Reminders to drink water throughout the day',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
      
      currentTime = currentTime.add(Duration(hours: interval));
    }
    
    // Reschedule for next day
    await _scheduleDailyNotification(
      id: 299,
      title: 'Water Reminders Set 💧',
      body: 'You\'ll get ${(12 ~/ interval)} reminders today to stay hydrated!',
      hour: 8,
      minute: 0,
      channelId: 'water_reminders',
      channelName: 'Water Reminders',
    );
  }

  // ==================== STREAK REMINDERS ====================
  
  Future<void> _scheduleStreakReminders(NotificationSettings settings) async {
    await _scheduleDailyNotification(
      id: 300,
      title: '🔥 Don\'t Break Your Streak!',
      body: 'You haven\'t logged your daily quest yet. Complete it before midnight to keep your streak alive!',
      hour: settings.streakReminderHour,
      minute: settings.streakReminderMinute,
      channelId: 'streak_reminders',
      channelName: 'Streak Reminders',
    );
  }

  // ==================== WEEKLY DIGEST ====================
  
  Future<void> _scheduleWeeklyDigest(NotificationSettings settings) async {
    await _scheduleWeeklyNotification(
      id: 400,
      title: '📊 Your Weekly Health Report',
      body: 'See your progress, achievements, and stats for this week!',
      day: settings.weeklyDigestDay,
      hour: settings.weeklyDigestHour,
      minute: settings.weeklyDigestMinute,
      channelId: 'weekly_digest',
      channelName: 'Weekly Digest',
    );
  }

  // ==================== MEAL PLAN REMINDERS ====================
  
  Future<void> _scheduleMealPlanReminders(NotificationSettings settings) async {
    await _scheduleDailyNotification(
      id: 500,
      title: '📋 Today\'s Meal Plan',
      body: 'Check your planned meals for today and stay on track with your nutrition goals!',
      hour: settings.mealPlanReminderHour,
      minute: 0,
      channelId: 'meal_plan_reminders',
      channelName: 'Meal Plan Reminders',
    );
  }

  // ==================== SMART COACH ====================
  
  Future<void> _scheduleSmartCoach(NotificationSettings settings) async {
    // Morning motivation
    await _scheduleDailyNotification(
      id: 600,
      title: '🌅 Good Morning!',
      body: 'Today is a new chance to be better. Check your goals and crush them!',
      hour: 7,
      minute: 30,
      channelId: 'smart_coach',
      channelName: 'Smart Coach',
    );
    
    // Afternoon check-in
    await _scheduleDailyNotification(
      id: 601,
      title: '💪 How\'s Your Day Going?',
      body: 'Take a moment to log your progress and stay on track!',
      hour: settings.coachCheckInHour,
      minute: 0,
      channelId: 'smart_coach',
      channelName: 'Smart Coach',
    );
    
    // Evening reflection
    await _scheduleDailyNotification(
      id: 602,
      title: '🌙 Evening Reflection',
      body: 'Review your day. What went well? What can you improve tomorrow?',
      hour: 20,
      minute: 30,
      channelId: 'smart_coach',
      channelName: 'Smart Coach',
    );
  }

  // ==================== ACHIEVEMENT NOTIFICATIONS ====================
  
  Future<void> showAchievementNotification({
    required String title,
    required String body,
    String? badgeIcon,
  }) async {
    if (kIsWeb) return;
    
    await _notificationsPlugin.show(
      700 + DateTime.now().millisecond,
      '🏆 $title',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'achievements',
          'Achievements',
          channelDescription: 'Celebration notifications for your achievements',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ==================== CUSTOM NOTIFICATIONS ====================
  
  Future<void> showCustomNotification({
    required int id,
    required String title,
    required String body,
    String channelId = 'custom',
    String channelName = 'Custom Notifications',
    String? payload,
  }) async {
    if (kIsWeb) return;

    await _notificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // ==================== HELPER METHODS ====================
  
  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
  }) async {
    if (kIsWeb) return;
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
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
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required String title,
    required String body,
    required int day, // 0 = Sunday, 6 = Saturday
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
  }) async {
    if (kIsWeb) return;
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    // Find next occurrence of this day
    while (scheduledDate.weekday % 7 != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (kIsWeb) return [];
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;
    
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final enabled = await androidImplementation.areNotificationsEnabled();
      return enabled ?? false;
    }
    
    return true; // iOS
  }
}
