import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../shared/models/notification_settings_model.dart';
import '../../../shared/providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsList(context, ref, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, WidgetRef ref, NotificationSettings settings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Sound Effects', Icons.volume_up),
        StatefulBuilder(
          builder: (ctx, setLocal) => _buildSwitchTile(
            title: 'In-App Sounds',
            subtitle: 'Plays a sound on messages, XP, level up, achievements',
            value: SoundService().enabled,
            onChanged: (v) async {
              await SoundService().setEnabled(v);
              if (v) SoundService().play(AppSound.success);
              setLocal(() {});
            },
          ),
        ),
        const Divider(height: 32),

        _buildSectionHeader('Meal Reminders', Icons.restaurant),
        _buildSwitchTile(
          title: 'Enable Meal Reminders',
          subtitle: 'Get reminded for breakfast, lunch, and dinner',
          value: settings.mealRemindersEnabled,
          onChanged: (value) => _updateSetting(ref, 'mealRemindersEnabled', value),
        ),
        if (settings.mealRemindersEnabled) ...[
          _buildTimeTile(
            title: 'Breakfast',
            icon: Icons.wb_sunny,
            hour: settings.breakfastReminderHour,
            minute: settings.breakfastReminderMinute,
            onTap: () => _showTimePicker(
              context,
              'Breakfast Reminder',
              settings.breakfastReminderHour,
              settings.breakfastReminderMinute,
              (hour, minute) {
                _updateSetting(ref, 'breakfastReminderHour', hour);
                _updateSetting(ref, 'breakfastReminderMinute', minute);
              },
            ),
          ),
          _buildTimeTile(
            title: 'Lunch',
            icon: Icons.wb_cloudy,
            hour: settings.lunchReminderHour,
            minute: settings.lunchReminderMinute,
            onTap: () => _showTimePicker(
              context,
              'Lunch Reminder',
              settings.lunchReminderHour,
              settings.lunchReminderMinute,
              (hour, minute) {
                _updateSetting(ref, 'lunchReminderHour', hour);
                _updateSetting(ref, 'lunchReminderMinute', minute);
              },
            ),
          ),
          _buildTimeTile(
            title: 'Dinner',
            icon: Icons.nights_stay,
            hour: settings.dinnerReminderHour,
            minute: settings.dinnerReminderMinute,
            onTap: () => _showTimePicker(
              context,
              'Dinner Reminder',
              settings.dinnerReminderHour,
              settings.dinnerReminderMinute,
              (hour, minute) {
                _updateSetting(ref, 'dinnerReminderHour', hour);
                _updateSetting(ref, 'dinnerReminderMinute', minute);
              },
            ),
          ),
        ],
        const Divider(height: 32),
        
        _buildSectionHeader('Water Reminders', Icons.water_drop),
        _buildSwitchTile(
          title: 'Enable Water Reminders',
          subtitle: 'Stay hydrated throughout the day',
          value: settings.waterRemindersEnabled,
          onChanged: (value) => _updateSetting(ref, 'waterRemindersEnabled', value),
        ),
        if (settings.waterRemindersEnabled) ...[
          _buildSliderTile(
            title: 'Reminder Interval',
            subtitle: 'Every ${settings.waterReminderIntervalHours} hours',
            value: settings.waterReminderIntervalHours.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            onChanged: (value) => _updateSetting(ref, 'waterReminderIntervalHours', value.toInt()),
          ),
          _buildSliderTile(
            title: 'Daily Water Goal',
            subtitle: '${settings.dailyWaterGoal} glasses',
            value: settings.dailyWaterGoal.toDouble(),
            min: 4,
            max: 16,
            divisions: 12,
            onChanged: (value) => _updateSetting(ref, 'dailyWaterGoal', value.toInt()),
          ),
        ],
        const Divider(height: 32),
        
        _buildSectionHeader('Streak & Progress', Icons.local_fire_department),
        _buildSwitchTile(
          title: 'Streak Reminders',
          subtitle: 'Don\'t break your daily streaks',
          value: settings.streakRemindersEnabled,
          onChanged: (value) => _updateSetting(ref, 'streakRemindersEnabled', value),
        ),
        if (settings.streakRemindersEnabled)
          _buildTimeTile(
            title: 'Reminder Time',
            icon: Icons.access_time,
            hour: settings.streakReminderHour,
            minute: settings.streakReminderMinute,
            onTap: () => _showTimePicker(
              context,
              'Streak Reminder',
              settings.streakReminderHour,
              settings.streakReminderMinute,
              (hour, minute) {
                _updateSetting(ref, 'streakReminderHour', hour);
                _updateSetting(ref, 'streakReminderMinute', minute);
              },
            ),
          ),
        _buildSwitchTile(
          title: 'Achievement Notifications',
          subtitle: 'Celebrate when you earn badges',
          value: settings.achievementNotificationsEnabled,
          onChanged: (value) => _updateSetting(ref, 'achievementNotificationsEnabled', value),
        ),
        const Divider(height: 32),
        
        _buildSectionHeader('Weekly Summary', Icons.calendar_view_week),
        _buildSwitchTile(
          title: 'Weekly Digest',
          subtitle: 'Get your health report every week',
          value: settings.weeklyDigestEnabled,
          onChanged: (value) => _updateSetting(ref, 'weeklyDigestEnabled', value),
        ),
        if (settings.weeklyDigestEnabled) ...[
          _buildDropdownTile(
            title: 'Day of Week',
            value: _getDayName(settings.weeklyDigestDay),
            onTap: () => _showDayPicker(context, settings.weeklyDigestDay, (day) {
              _updateSetting(ref, 'weeklyDigestDay', day);
            }),
          ),
          _buildTimeTile(
            title: 'Time',
            icon: Icons.access_time,
            hour: settings.weeklyDigestHour,
            minute: settings.weeklyDigestMinute,
            onTap: () => _showTimePicker(
              context,
              'Weekly Digest',
              settings.weeklyDigestHour,
              settings.weeklyDigestMinute,
              (hour, minute) {
                _updateSetting(ref, 'weeklyDigestHour', hour);
                _updateSetting(ref, 'weeklyDigestMinute', minute);
              },
            ),
          ),
        ],
        const Divider(height: 32),
        
        _buildSectionHeader('Smart Coach', Icons.smart_toy),
        _buildSwitchTile(
          title: 'Enable Smart Coach',
          subtitle: 'AI-powered motivation and tips',
          value: settings.smartCoachEnabled,
          onChanged: (value) => _updateSetting(ref, 'smartCoachEnabled', value),
        ),
        if (settings.smartCoachEnabled)
          _buildTimeTile(
            title: 'Afternoon Check-in',
            icon: Icons.access_time,
            hour: settings.coachCheckInHour,
            minute: 0,
            onTap: () => _showTimePicker(
              context,
              'Coach Check-in',
              settings.coachCheckInHour,
              0,
              (hour, minute) => _updateSetting(ref, 'coachCheckInHour', hour),
            ),
          ),
        const Divider(height: 32),
        
        _buildSectionHeader('Quiet Hours', Icons.do_not_disturb),
        _buildSwitchTile(
          title: 'Enable Quiet Hours',
          subtitle: 'No notifications during these hours',
          value: settings.quietHoursEnabled,
          onChanged: (value) => _updateSetting(ref, 'quietHoursEnabled', value),
        ),
        if (settings.quietHoursEnabled) ...[
          _buildTimeTile(
            title: 'Start',
            icon: Icons.bedtime,
            hour: settings.quietHoursStartHour,
            minute: settings.quietHoursStartMinute,
            onTap: () => _showTimePicker(
              context,
              'Quiet Hours Start',
              settings.quietHoursStartHour,
              settings.quietHoursStartMinute,
              (hour, minute) {
                _updateSetting(ref, 'quietHoursStartHour', hour);
                _updateSetting(ref, 'quietHoursStartMinute', minute);
              },
            ),
          ),
          _buildTimeTile(
            title: 'End',
            icon: Icons.wb_sunny,
            hour: settings.quietHoursEndHour,
            minute: settings.quietHoursEndMinute,
            onTap: () => _showTimePicker(
              context,
              'Quiet Hours End',
              settings.quietHoursEndHour,
              settings.quietHoursEndMinute,
              (hour, minute) {
                _updateSetting(ref, 'quietHoursEndHour', hour);
                _updateSetting(ref, 'quietHoursEndMinute', minute);
              },
            ),
          ),
        ],
        const Divider(height: 32),
        
        _buildSectionHeader('Meal Planning', Icons.event_note),
        _buildSwitchTile(
          title: 'Meal Plan Reminders',
          subtitle: 'Daily reminder to check your meal plan',
          value: settings.mealPlanRemindersEnabled,
          onChanged: (value) => _updateSetting(ref, 'mealPlanRemindersEnabled', value),
        ),
        if (settings.mealPlanRemindersEnabled)
          _buildTimeTile(
            title: 'Reminder Time',
            icon: Icons.access_time,
            hour: settings.mealPlanReminderHour,
            minute: 0,
            onTap: () => _showTimePicker(
              context,
              'Meal Plan Reminder',
              settings.mealPlanReminderHour,
              0,
              (hour, minute) => _updateSetting(ref, 'mealPlanReminderHour', hour),
            ),
          ),
        const SizedBox(height: 32),
        
        // Test notifications button
        ElevatedButton.icon(
          onPressed: () => _showTestNotification(context),
          icon: const Icon(Icons.notifications_active),
          label: const Text('Test Notification'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 16),
        
        // Save and reschedule button
        ElevatedButton.icon(
          onPressed: () => _rescheduleNotifications(context, ref, settings),
          icon: const Icon(Icons.save),
          label: const Text('Apply Changes'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required IconData icon,
    required int hour,
    required int minute,
    required VoidCallback onTap,
  }) {
    final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        trailing: Text(
          timeString,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.toInt().toString(),
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }

  void _updateSetting(WidgetRef ref, String field, dynamic value) {
    ref.read(notificationSettingsNotifierProvider.notifier).updateSetting(field, value);
  }

  String _getDayName(int day) {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    return days[day];
  }

  Future<void> _showTimePicker(
    BuildContext context,
    String title,
    int initialHour,
    int initialMinute,
    Function(int hour, int minute) onTimeSelected,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: title,
    );
    
    if (picked != null) {
      onTimeSelected(picked.hour, picked.minute);
    }
  }

  Future<void> _showDayPicker(BuildContext context, int currentDay, Function(int) onDaySelected) async {
    final days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    final int? selected = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Day'),
        children: days.asMap().entries.map((entry) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, entry.key),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontWeight: entry.key == currentDay ? FontWeight.bold : FontWeight.normal,
                  color: entry.key == currentDay ? AppColors.primary : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
    
    if (selected != null) {
      onDaySelected(selected);
    }
  }

  Future<void> _showTestNotification(BuildContext context) async {
    final notificationService = NotificationService();
    await notificationService.showCustomNotification(
      id: 9999,
      title: '🔔 Test Notification',
      body: 'Your notifications are working! 🎉',
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _rescheduleNotifications(
    BuildContext context,
    WidgetRef ref,
    NotificationSettings settings,
  ) async {
    final notificationService = NotificationService();
    await notificationService.scheduleAllNotifications(settings);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
