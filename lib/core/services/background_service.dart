import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:flutter/services.dart';

class BackgroundServiceManager {
  static const MethodChannel _nativeChannel = MethodChannel(
    'com.example.better_you/lock',
  );

  static Future<void> initializeService() async {
    if (kIsWeb) return;

    final service = FlutterBackgroundService();

    // Create notification channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'better_you_monitoring',
      'Better You Monitoring',
      description: 'Tracking app usage to keep you productive',
      importance: Importance
          .low, // importance must be at least low for foreground service
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'better_you_monitoring',
        initialNotificationTitle: 'Better You Monitoring',
        initialNotificationContent: 'Tracking app usage to keep you productive',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: (service) => false,
      ),
    );

    service.startService();
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
    }

    Map<String, dynamic> appLimits = {};
    String? lastTriggeredApp;
    DateTime? lastTriggeredTime;

    // Load initial limits from prefs
    final prefs = await SharedPreferences.getInstance();
    final limitsJson = prefs.getString('app_limits') ?? '{}';
    appLimits = json.decode(limitsJson);
    Map<String, bool> lockedAppsStatus = {};

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      service.on('updateLimits').listen((event) {
        if (event != null) {
          appLimits = event;
          debugPrint(
            'BetterYouBG: Limits updated: ${appLimits.keys.length} apps',
          );
        }
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Main monitoring loop
    Timer.periodic(const Duration(seconds: 15), (timer) async {
      try {
        if (service is AndroidServiceInstance) {
          if (!(await service.isForegroundService())) {
            await service.setAsForegroundService();
          }

          final bool? hasPermission = await UsageStats.checkUsagePermission();
          bool hasOverlay = true;
          try {
            hasOverlay =
                await _nativeChannel.invokeMethod('checkOverlayPermission') ??
                false;
          } catch (e) {
            // ignore
          }

          if (hasPermission == null || !hasPermission) {
            service.setForegroundNotificationInfo(
              title: 'Better You Monitoring',
              content: 'Please grant usage access to track your habits!',
            );
            return;
          }

          if (!hasOverlay) {
            service.setForegroundNotificationInfo(
              title: 'Action Required',
              content: 'Overlay permission needed to show the lock screen!',
            );
          }

          if (appLimits.isEmpty) {
            service.setForegroundNotificationInfo(
              title: 'Better You Monitoring',
              content: 'No app limits set yet.',
            );
            return;
          }

          // Check current foreground app
          final lastApp = await _getLastUsedApp();

          if (lastApp == 'com.example.better_you') {
            // We are already in our app, don't trigger again
            lastTriggeredApp = null;
            return;
          }

          // Show current monitoring status in notification
          String status = "Monitoring ${appLimits.length} apps...";
          if (lastApp != null && lastApp != 'com.example.better_you') {
            status = "Active: ${lastApp.split('.').last}";
          } else {
            status = "Ready to keep you productive!";
          }

          service.setForegroundNotificationInfo(
            title: 'Better You Monitoring',
            content: status,
          );

          if (lastApp == null || lastApp == 'com.example.better_you') {
            // If we are back in our app, clear the last triggered app to allow re-locking if they switch back
            lastTriggeredApp = null;
            return;
          }

          if (appLimits.containsKey(lastApp)) {
            final limitData = appLimits[lastApp];
            final limitMins = limitData['limit'] ?? 0;

            final dailyUsage = await _getDailyUsage();
            final currentUsage = dailyUsage[lastApp] ?? 0;

            if (currentUsage >= limitMins) {
              // Mark as locked for AccessibilityService
              if (lockedAppsStatus[lastApp] != true) {
                lockedAppsStatus[lastApp] = true;
                await prefs.setString(
                  'locked_apps_status',
                  json.encode(lockedAppsStatus),
                );
              }

              // Only trigger if it's a new app or if enough time has passed (to avoid intent spamming)
              final now = DateTime.now();
              if (lastTriggeredApp != lastApp ||
                  lastTriggeredTime == null ||
                  now.difference(lastTriggeredTime!).inSeconds > 10) {
                debugPrint(
                  'BetterYouBG: LIMIT REACHED for $lastApp! Triggering lock...',
                );

                lastTriggeredApp = lastApp;
                lastTriggeredTime = now;

                // Trigger the activity launch and notification
                _triggerAppLock(
                  lastApp,
                  limitData['quest'] ?? 'Complete your quest',
                );
              }
            }
          } else {
            // App is not limited, clear last triggered
            lastTriggeredApp = null;
          }
        }
      } catch (e) {
        debugPrint('BetterYouBG: Error in monitoring loop: $e');
      }
    });
  }

  static Future<String?> _getLastUsedApp() async {
    if (!Platform.isAndroid) return null;
    DateTime now = DateTime.now();
    DateTime oneMinAgo = now.subtract(const Duration(minutes: 1));

    try {
      // Use queryEvents for more accurate foreground app detection
      List<EventUsageInfo> events = await UsageStats.queryEvents(
        oneMinAgo,
        now,
      );

      if (events.isNotEmpty) {
        // Sort by timestamp descending
        events.sort(
          (a, b) => (int.tryParse(b.timeStamp ?? '0') ?? 0).compareTo(
            int.tryParse(a.timeStamp ?? '0') ?? 0,
          ),
        );

        for (var event in events) {
          // Event type 1 is MOVE_TO_FOREGROUND or ACTIVITY_RESUMED
          if (event.eventType == '1' &&
              event.packageName != 'com.example.better_you') {
            return event.packageName;
          }
        }
      }

      // Fallback to queryUsageStats if no events found
      List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        oneMinAgo,
        now,
      );

      if (usageStats.isEmpty) return null;

      final otherApps = usageStats
          .where((a) => a.packageName != 'com.example.better_you')
          .toList();

      if (otherApps.isEmpty) return 'com.example.better_you';

      otherApps.sort(
        (a, b) => (int.tryParse(b.lastTimeUsed ?? '0') ?? 0).compareTo(
          int.tryParse(a.lastTimeUsed ?? '0') ?? 0,
        ),
      );

      return otherApps.first.packageName;
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, int>> _getDailyUsage() async {
    if (!Platform.isAndroid) return {};
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
      startOfDay,
      now,
    );
    Map<String, int> dailyUsage = {};
    for (var info in usageStats) {
      int totalTime = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      if (totalTime > 0) {
        dailyUsage[info.packageName!] =
            (dailyUsage[info.packageName!] ?? 0) + totalTime;
      }
    }
    return dailyUsage.map(
      (key, value) => MapEntry(key, (value / 60000).round()),
    );
  }

  static void _triggerAppLock(String pkg, String quest) async {
    // Notify the app via stream
    final service = FlutterBackgroundService();
    service.invoke('locked_app', {'locked_app': pkg, 'quest': quest});

    // Attempt direct intent launch
    try {
      final intent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.example.better_you',
        componentName: 'com.example.better_you.MainActivity',
        flags: [
          Flag.FLAG_ACTIVITY_NEW_TASK,
          Flag.FLAG_ACTIVITY_REORDER_TO_FRONT,
          Flag.FLAG_ACTIVITY_SINGLE_TOP,
          Flag.FLAG_ACTIVITY_CLEAR_TOP,
        ],
        arguments: {'locked_app': pkg, 'quest': quest},
      );
      await intent.launch();
    } catch (e) {
      debugPrint(
        'BetterYouBG: Direct intent launch failed, showing notification...',
      );
    }

    // Fallback/Reinforcement: Show high-priority notification that triggers the activity
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'better_you_intervention',
          'Better You Intervention',
          channelDescription: 'Required quests to unlock distracting apps',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          ongoing: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      999,
      'Better You Intervention',
      'Complete your quest to unlock ${pkg.split('.').last}',
      platformChannelSpecifics,
      payload: json.encode({'locked_app': pkg, 'quest': quest}),
    );
  }
}
