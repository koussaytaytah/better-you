// Stub implementation for usage_stats package
// Original package removed due to Android SDK 36 incompatibility

class UsageInfo {
  final String packageName;
  final String? totalTimeInForeground;
  final String? lastTimeUsed;

  UsageInfo({
    required this.packageName,
    this.totalTimeInForeground,
    this.lastTimeUsed,
  });
}

class UsageStats {
  static Future<bool> checkUsagePermission() async {
    return false;
  }

  static Future<void> grantUsagePermission() async {}

  static Future<List<UsageInfo>> queryUsageStats(DateTime start, DateTime end) async {
    return [];
  }
}
