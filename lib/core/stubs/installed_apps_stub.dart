// Stub implementation for installed_apps package
// Original package removed due to Android SDK 36 incompatibility
import 'dart:typed_data';

class AppInfo {
  final String name;
  final String packageName;
  final Uint8List? icon;

  AppInfo({
    required this.name,
    required this.packageName,
    this.icon,
  });
}

class InstalledApps {
  static Future<List<AppInfo>> getInstalledApps([bool includeIcon = false, bool excludeSystemApps = false]) async {
    return [];
  }
}
