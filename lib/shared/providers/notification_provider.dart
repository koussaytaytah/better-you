import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/notification_settings_repository.dart';
import '../../core/services/notification_service.dart';
import '../models/notification_settings_model.dart';
import 'auth_provider.dart';

final notificationSettingsRepositoryProvider = Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepository();
});

final notificationSettingsProvider = StreamProvider<NotificationSettings>((ref) {
  final user = ref.watch(currentUserProvider);
  final repository = ref.watch(notificationSettingsRepositoryProvider);
  
  if (user == null) {
    return Stream.value(NotificationSettings(userId: ''));
  }
  
  return repository.watchSettings(user.uid);
});

class NotificationSettingsNotifier extends StateNotifier<AsyncValue<NotificationSettings>> {
  final NotificationSettingsRepository _repository;
  // ignore: unused_field
  final Ref _ref;

  NotificationSettingsNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading());

  Future<void> loadSettings(String userId) async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getSettings(userId);
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveSettings(NotificationSettings settings) async {
    try {
      await _repository.saveSettings(settings);
      state = AsyncValue.data(settings);
      
      // Reschedule notifications with new settings
      final notificationService = NotificationService();
      await notificationService.scheduleAllNotifications(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateSetting(String field, dynamic value) async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      await _repository.updateSetting(currentSettings.userId, field, value);
      
      // Update local state
      final updatedSettings = _updateSettingInModel(currentSettings, field, value);
      state = AsyncValue.data(updatedSettings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  NotificationSettings _updateSettingInModel(NotificationSettings settings, String field, dynamic value) {
    // Create a map of current settings and update the specific field
    final map = settings.toFirestore();
    map[field] = value;
    
    // Return updated settings
    return NotificationSettings(
      userId: map['userId'] ?? settings.userId,
      mealRemindersEnabled: map['mealRemindersEnabled'] ?? settings.mealRemindersEnabled,
      breakfastReminderHour: map['breakfastReminderHour'] ?? settings.breakfastReminderHour,
      breakfastReminderMinute: map['breakfastReminderMinute'] ?? settings.breakfastReminderMinute,
      lunchReminderHour: map['lunchReminderHour'] ?? settings.lunchReminderHour,
      lunchReminderMinute: map['lunchReminderMinute'] ?? settings.lunchReminderMinute,
      dinnerReminderHour: map['dinnerReminderHour'] ?? settings.dinnerReminderHour,
      dinnerReminderMinute: map['dinnerReminderMinute'] ?? settings.dinnerReminderMinute,
      waterRemindersEnabled: map['waterRemindersEnabled'] ?? settings.waterRemindersEnabled,
      waterReminderIntervalHours: map['waterReminderIntervalHours'] ?? settings.waterReminderIntervalHours,
      dailyWaterGoal: map['dailyWaterGoal'] ?? settings.dailyWaterGoal,
      streakRemindersEnabled: map['streakRemindersEnabled'] ?? settings.streakRemindersEnabled,
      streakReminderHour: map['streakReminderHour'] ?? settings.streakReminderHour,
      streakReminderMinute: map['streakReminderMinute'] ?? settings.streakReminderMinute,
      weeklyDigestEnabled: map['weeklyDigestEnabled'] ?? settings.weeklyDigestEnabled,
      weeklyDigestDay: map['weeklyDigestDay'] ?? settings.weeklyDigestDay,
      weeklyDigestHour: map['weeklyDigestHour'] ?? settings.weeklyDigestHour,
      weeklyDigestMinute: map['weeklyDigestMinute'] ?? settings.weeklyDigestMinute,
      achievementNotificationsEnabled: map['achievementNotificationsEnabled'] ?? settings.achievementNotificationsEnabled,
      smartCoachEnabled: map['smartCoachEnabled'] ?? settings.smartCoachEnabled,
      coachCheckInHour: map['coachCheckInHour'] ?? settings.coachCheckInHour,
      quietHoursEnabled: map['quietHoursEnabled'] ?? settings.quietHoursEnabled,
      quietHoursStartHour: map['quietHoursStartHour'] ?? settings.quietHoursStartHour,
      quietHoursStartMinute: map['quietHoursStartMinute'] ?? settings.quietHoursStartMinute,
      quietHoursEndHour: map['quietHoursEndHour'] ?? settings.quietHoursEndHour,
      quietHoursEndMinute: map['quietHoursEndMinute'] ?? settings.quietHoursEndMinute,
      mealPlanRemindersEnabled: map['mealPlanRemindersEnabled'] ?? settings.mealPlanRemindersEnabled,
      mealPlanReminderHour: map['mealPlanReminderHour'] ?? settings.mealPlanReminderHour,
    );
  }

  Future<void> applyAndReschedule() async {
    final currentSettings = state.value;
    if (currentSettings == null) return;

    try {
      final notificationService = NotificationService();
      await notificationService.scheduleAllNotifications(currentSettings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final notificationSettingsNotifierProvider = StateNotifierProvider<NotificationSettingsNotifier, AsyncValue<NotificationSettings>>((ref) {
  final repository = ref.watch(notificationSettingsRepositoryProvider);
  return NotificationSettingsNotifier(repository, ref);
});

// Provider to check notification status
final notificationStatusProvider = FutureProvider<bool>((ref) async {
  final notificationService = NotificationService();
  return notificationService.areNotificationsEnabled();
});

// Provider for pending notifications count
final pendingNotificationsProvider = FutureProvider<int>((ref) async {
  final notificationService = NotificationService();
  final pending = await notificationService.getPendingNotifications();
  return pending.length;
});
