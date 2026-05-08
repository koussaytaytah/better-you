import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettings {
  final String userId;
  
  // Meal reminders
  final bool mealRemindersEnabled;
  final int breakfastReminderHour;
  final int breakfastReminderMinute;
  final int lunchReminderHour;
  final int lunchReminderMinute;
  final int dinnerReminderHour;
  final int dinnerReminderMinute;
  
  // Water reminders
  final bool waterRemindersEnabled;
  final int waterReminderIntervalHours;
  final int dailyWaterGoal;
  
  // Streak and daily reminders
  final bool streakRemindersEnabled;
  final int streakReminderHour;
  final int streakReminderMinute;
  
  // Weekly digest
  final bool weeklyDigestEnabled;
  final int weeklyDigestDay; // 0 = Sunday, 6 = Saturday
  final int weeklyDigestHour;
  final int weeklyDigestMinute;
  
  // Achievement notifications
  final bool achievementNotificationsEnabled;
  
  // Smart coach
  final bool smartCoachEnabled;
  final int coachCheckInHour;
  
  // Quiet hours
  final bool quietHoursEnabled;
  final int quietHoursStartHour;
  final int quietHoursStartMinute;
  final int quietHoursEndHour;
  final int quietHoursEndMinute;
  
  // Meal plan reminders
  final bool mealPlanRemindersEnabled;
  final int mealPlanReminderHour;

  NotificationSettings({
    required this.userId,
    this.mealRemindersEnabled = true,
    this.breakfastReminderHour = 8,
    this.breakfastReminderMinute = 0,
    this.lunchReminderHour = 12,
    this.lunchReminderMinute = 0,
    this.dinnerReminderHour = 19,
    this.dinnerReminderMinute = 0,
    this.waterRemindersEnabled = true,
    this.waterReminderIntervalHours = 2,
    this.dailyWaterGoal = 8,
    this.streakRemindersEnabled = true,
    this.streakReminderHour = 21,
    this.streakReminderMinute = 0,
    this.weeklyDigestEnabled = true,
    this.weeklyDigestDay = 0,
    this.weeklyDigestHour = 10,
    this.weeklyDigestMinute = 0,
    this.achievementNotificationsEnabled = true,
    this.smartCoachEnabled = true,
    this.coachCheckInHour = 15,
    this.quietHoursEnabled = false,
    this.quietHoursStartHour = 22,
    this.quietHoursStartMinute = 0,
    this.quietHoursEndHour = 7,
    this.quietHoursEndMinute = 0,
    this.mealPlanRemindersEnabled = true,
    this.mealPlanReminderHour = 8,
  });

  factory NotificationSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationSettings(
      userId: doc.id,
      mealRemindersEnabled: data['mealRemindersEnabled'] ?? true,
      breakfastReminderHour: data['breakfastReminderHour'] ?? 8,
      breakfastReminderMinute: data['breakfastReminderMinute'] ?? 0,
      lunchReminderHour: data['lunchReminderHour'] ?? 12,
      lunchReminderMinute: data['lunchReminderMinute'] ?? 0,
      dinnerReminderHour: data['dinnerReminderHour'] ?? 19,
      dinnerReminderMinute: data['dinnerReminderMinute'] ?? 0,
      waterRemindersEnabled: data['waterRemindersEnabled'] ?? true,
      waterReminderIntervalHours: data['waterReminderIntervalHours'] ?? 2,
      dailyWaterGoal: data['dailyWaterGoal'] ?? 8,
      streakRemindersEnabled: data['streakRemindersEnabled'] ?? true,
      streakReminderHour: data['streakReminderHour'] ?? 21,
      streakReminderMinute: data['streakReminderMinute'] ?? 0,
      weeklyDigestEnabled: data['weeklyDigestEnabled'] ?? true,
      weeklyDigestDay: data['weeklyDigestDay'] ?? 0,
      weeklyDigestHour: data['weeklyDigestHour'] ?? 10,
      weeklyDigestMinute: data['weeklyDigestMinute'] ?? 0,
      achievementNotificationsEnabled: data['achievementNotificationsEnabled'] ?? true,
      smartCoachEnabled: data['smartCoachEnabled'] ?? true,
      coachCheckInHour: data['coachCheckInHour'] ?? 15,
      quietHoursEnabled: data['quietHoursEnabled'] ?? false,
      quietHoursStartHour: data['quietHoursStartHour'] ?? 22,
      quietHoursStartMinute: data['quietHoursStartMinute'] ?? 0,
      quietHoursEndHour: data['quietHoursEndHour'] ?? 7,
      quietHoursEndMinute: data['quietHoursEndMinute'] ?? 0,
      mealPlanRemindersEnabled: data['mealPlanRemindersEnabled'] ?? true,
      mealPlanReminderHour: data['mealPlanReminderHour'] ?? 8,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mealRemindersEnabled': mealRemindersEnabled,
      'breakfastReminderHour': breakfastReminderHour,
      'breakfastReminderMinute': breakfastReminderMinute,
      'lunchReminderHour': lunchReminderHour,
      'lunchReminderMinute': lunchReminderMinute,
      'dinnerReminderHour': dinnerReminderHour,
      'dinnerReminderMinute': dinnerReminderMinute,
      'waterRemindersEnabled': waterRemindersEnabled,
      'waterReminderIntervalHours': waterReminderIntervalHours,
      'dailyWaterGoal': dailyWaterGoal,
      'streakRemindersEnabled': streakRemindersEnabled,
      'streakReminderHour': streakReminderHour,
      'streakReminderMinute': streakReminderMinute,
      'weeklyDigestEnabled': weeklyDigestEnabled,
      'weeklyDigestDay': weeklyDigestDay,
      'weeklyDigestHour': weeklyDigestHour,
      'weeklyDigestMinute': weeklyDigestMinute,
      'achievementNotificationsEnabled': achievementNotificationsEnabled,
      'smartCoachEnabled': smartCoachEnabled,
      'coachCheckInHour': coachCheckInHour,
      'quietHoursEnabled': quietHoursEnabled,
      'quietHoursStartHour': quietHoursStartHour,
      'quietHoursStartMinute': quietHoursStartMinute,
      'quietHoursEndHour': quietHoursEndHour,
      'quietHoursEndMinute': quietHoursEndMinute,
      'mealPlanRemindersEnabled': mealPlanRemindersEnabled,
      'mealPlanReminderHour': mealPlanReminderHour,
    };
  }

  NotificationSettings copyWith({
    String? userId,
    bool? mealRemindersEnabled,
    int? breakfastReminderHour,
    int? breakfastReminderMinute,
    int? lunchReminderHour,
    int? lunchReminderMinute,
    int? dinnerReminderHour,
    int? dinnerReminderMinute,
    bool? waterRemindersEnabled,
    int? waterReminderIntervalHours,
    int? dailyWaterGoal,
    bool? streakRemindersEnabled,
    int? streakReminderHour,
    int? streakReminderMinute,
    bool? weeklyDigestEnabled,
    int? weeklyDigestDay,
    int? weeklyDigestHour,
    int? weeklyDigestMinute,
    bool? achievementNotificationsEnabled,
    bool? smartCoachEnabled,
    int? coachCheckInHour,
    bool? quietHoursEnabled,
    int? quietHoursStartHour,
    int? quietHoursStartMinute,
    int? quietHoursEndHour,
    int? quietHoursEndMinute,
    bool? mealPlanRemindersEnabled,
    int? mealPlanReminderHour,
  }) {
    return NotificationSettings(
      userId: userId ?? this.userId,
      mealRemindersEnabled: mealRemindersEnabled ?? this.mealRemindersEnabled,
      breakfastReminderHour: breakfastReminderHour ?? this.breakfastReminderHour,
      breakfastReminderMinute: breakfastReminderMinute ?? this.breakfastReminderMinute,
      lunchReminderHour: lunchReminderHour ?? this.lunchReminderHour,
      lunchReminderMinute: lunchReminderMinute ?? this.lunchReminderMinute,
      dinnerReminderHour: dinnerReminderHour ?? this.dinnerReminderHour,
      dinnerReminderMinute: dinnerReminderMinute ?? this.dinnerReminderMinute,
      waterRemindersEnabled: waterRemindersEnabled ?? this.waterRemindersEnabled,
      waterReminderIntervalHours: waterReminderIntervalHours ?? this.waterReminderIntervalHours,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      streakRemindersEnabled: streakRemindersEnabled ?? this.streakRemindersEnabled,
      streakReminderHour: streakReminderHour ?? this.streakReminderHour,
      streakReminderMinute: streakReminderMinute ?? this.streakReminderMinute,
      weeklyDigestEnabled: weeklyDigestEnabled ?? this.weeklyDigestEnabled,
      weeklyDigestDay: weeklyDigestDay ?? this.weeklyDigestDay,
      weeklyDigestHour: weeklyDigestHour ?? this.weeklyDigestHour,
      weeklyDigestMinute: weeklyDigestMinute ?? this.weeklyDigestMinute,
      achievementNotificationsEnabled: achievementNotificationsEnabled ?? this.achievementNotificationsEnabled,
      smartCoachEnabled: smartCoachEnabled ?? this.smartCoachEnabled,
      coachCheckInHour: coachCheckInHour ?? this.coachCheckInHour,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStartHour: quietHoursStartHour ?? this.quietHoursStartHour,
      quietHoursStartMinute: quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndHour: quietHoursEndHour ?? this.quietHoursEndHour,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
      mealPlanRemindersEnabled: mealPlanRemindersEnabled ?? this.mealPlanRemindersEnabled,
      mealPlanReminderHour: mealPlanReminderHour ?? this.mealPlanReminderHour,
    );
  }

  // Helper method to check if current time is within quiet hours
  bool isInQuietHours(DateTime now) {
    if (!quietHoursEnabled) return false;
    
    final startMinutes = quietHoursStartHour * 60 + quietHoursStartMinute;
    final endMinutes = quietHoursEndHour * 60 + quietHoursEndMinute;
    final currentMinutes = now.hour * 60 + now.minute;
    
    if (startMinutes < endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Spanning midnight
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  // Get next quiet hours end time
  DateTime getNextQuietHoursEnd(DateTime now) {
    if (!quietHoursEnabled) return now;
    
    var endTime = DateTime(
      now.year,
      now.month,
      now.day,
      quietHoursEndHour,
      quietHoursEndMinute,
    );
    
    if (endTime.isBefore(now)) {
      endTime = endTime.add(const Duration(days: 1));
    }
    
    return endTime;
  }
}
