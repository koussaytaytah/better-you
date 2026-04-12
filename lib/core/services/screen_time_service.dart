import 'package:usage_stats/usage_stats.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenTimeService {
  static final ScreenTimeService _instance = ScreenTimeService._internal();
  factory ScreenTimeService() => _instance;
  ScreenTimeService._internal();

  Future<bool> checkPermission() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    bool isUsageGranted = await checkUsagePermissionOnly();
    bool isOverlayGranted = await checkOverlayPermissionOnly();
    bool isNotificationGranted = await checkNotificationPermissionOnly();

    // Check accessibility as well
    const channel = MethodChannel('com.example.better_you/lock');
    bool isAccessibilityGranted = false;
    try {
      isAccessibilityGranted =
          await channel.invokeMethod('isAccessibilityServiceEnabled') ?? false;
    } catch (e) {
      // ignore
    }

    return isUsageGranted &&
        isOverlayGranted &&
        isNotificationGranted &&
        isAccessibilityGranted;
  }

  Future<bool> checkUsagePermissionOnly() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    bool? isUsageGranted = await UsageStats.checkUsagePermission();
    return isUsageGranted ?? false;
  }

  Future<bool> checkOverlayPermissionOnly() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    // Use native channel as fallback for overlay permission check
    const channel = MethodChannel('com.example.better_you/lock');
    try {
      final bool? hasNativePermission = await channel.invokeMethod(
        'checkOverlayPermission',
      );
      debugPrint('BetterYou: Native overlay check: $hasNativePermission');
      if (hasNativePermission == true) return true;
    } catch (e) {
      debugPrint('BetterYou: Error in native overlay check: $e');
    }

    final status = await Permission.systemAlertWindow.status;
    debugPrint('BetterYou: Permission handler overlay status: $status');
    return status.isGranted;
  }

  Future<bool> checkNotificationPermissionOnly() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    return await Permission.notification.isGranted;
  }

  Future<void> requestUsagePermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await UsageStats.grantUsagePermission();
  }

  Future<void> requestOverlayPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await Permission.systemAlertWindow.request();
  }

  Future<void> requestNotificationPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await Permission.notification.request();
  }

  Future<Map<String, int>> getDailyUsage() async {
    if (kIsWeb || !Platform.isAndroid) return {};

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

    // totalTimeInForeground is in milliseconds, convert to minutes
    return dailyUsage.map(
      (key, value) => MapEntry(key, (value / 60000).round()),
    );
  }

  Future<String?> getLastUsedApp() async {
    if (kIsWeb || !Platform.isAndroid) return null;

    DateTime now = DateTime.now();
    DateTime oneMinAgo = now.subtract(const Duration(minutes: 1));

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
      oneMinAgo,
      now,
    );
    if (usageStats.isEmpty) return null;

    // Sort by last time used to find the one currently in foreground
    usageStats.sort(
      (a, b) => (int.tryParse(b.lastTimeUsed ?? '0') ?? 0).compareTo(
        int.tryParse(a.lastTimeUsed ?? '0') ?? 0,
      ),
    );

    return usageStats.first.packageName;
  }

  Future<List<UsageInfo>> getInstalledApps() async {
    if (kIsWeb || !Platform.isAndroid) return [];

    DateTime now = DateTime.now();
    DateTime startDate = now.subtract(const Duration(days: 30));

    List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
      startDate,
      now,
    );

    // Filter by package name to ensure unique list
    final Map<String, UsageInfo> uniqueApps = {};
    for (var info in usageStats) {
      if (info.packageName != null) {
        uniqueApps[info.packageName!] = info;
      }
    }
    return uniqueApps.values.toList();
  }
}
