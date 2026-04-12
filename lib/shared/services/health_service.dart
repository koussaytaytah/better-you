import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/logger.dart';

final healthServiceProvider = Provider((ref) => HealthService());

class HealthService {
  final Health _health = Health();

  static const List<HealthDataType> _dataTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  ];

  Future<bool> requestPermissions() async {
    AppLogger.i("Requesting health permissions...");

    try {
      // 1. Request basic Android permissions first
      Map<Permission, PermissionStatus> statuses = await [
        Permission.activityRecognition,
        Permission.sensors,
      ].request();

      if (statuses[Permission.activityRecognition] !=
          PermissionStatus.granted) {
        throw Exception("Activity recognition permission denied by system.");
      }

      // 2. Check for Health Connect and handle fallback
      HealthConnectSdkStatus? status = await _health
          .getHealthConnectSdkStatus();

      if (status != HealthConnectSdkStatus.sdkAvailable) {
        AppLogger.w(
          "Health Connect not available, attempting Google Fit fallback...",
        );
      } else {
        AppLogger.i("Health Connect is available.");
      }

      // 3. Request health data permissions
      final permissions = _dataTypes.map((e) => HealthDataAccess.READ).toList();

      bool? hasPermissions = await _health.hasPermissions(
        _dataTypes,
        permissions: permissions,
      );

      if (hasPermissions == null || !hasPermissions) {
        AppLogger.i("Requesting Health authorization...");
        bool authorized = await _health.requestAuthorization(
          _dataTypes,
          permissions: permissions,
        );
        if (!authorized) {
          throw Exception("Health data authorization denied by user.");
        }
      }
    } catch (e, stack) {
      AppLogger.e("Permission error", e, stack);
      rethrow;
    }

    return true;
  }

  Future<void> installHealthConnect() async {
    await _health.installHealthConnect();
  }

  Future<Map<String, dynamic>> fetchHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    try {
      // Fetch steps for today
      int? steps = await _health.getTotalStepsInInterval(midnight, now);

      // Fetch sleep for the last 24 hours
      final yesterday = now.subtract(const Duration(hours: 24));
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: [
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_REM,
        ],
      );

      double totalSleepMinutes = 0;
      for (var point in healthData) {
        final start = point.dateFrom;
        final end = point.dateTo;
        totalSleepMinutes += end.difference(start).inMinutes;
      }

      return {'steps': steps ?? 0, 'sleepMinutes': totalSleepMinutes};
    } catch (e, stack) {
      AppLogger.e("Error fetching health data", e, stack);
      return {'steps': 0, 'sleepMinutes': 0.0};
    }
  }
}
