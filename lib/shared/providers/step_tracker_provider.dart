import 'package:pedometer/pedometer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../../core/utils/logger.dart';

final stepTrackerProvider = Provider((ref) => StepTrackerController(ref));

class StepTrackerController {
  final Ref _ref;
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  StepTrackerController(this._ref);

  Future<bool> requestPermissions() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  void startTracking() async {
    try {
      final hasPermission = await Permission.activityRecognition.isGranted;
      if (!hasPermission) {
        AppLogger.w("Cannot start tracking: Permission not granted.");
        return;
      }

      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
      );

      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatus,
        onError: _onPedestrianStatusError,
      );
    } catch (e, stack) {
      AppLogger.e("Error starting pedometer", e, stack);
    }
  }

  void _onStepCount(StepCount event) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    // Pedometer gives total steps since last boot.
    // For a truly professional app, we should store the 'start steps' for the day.
    // However, since we have the 'health' package for daily totals,
    // we'll use this to trigger a sync when we detect movement.

    AppLogger.i("Steps detected: ${event.steps}");
    // Every time we detect steps, we can trigger a silent sync with HealthService
    // or just update a local counter if we have the baseline.
  }

  void _onPedestrianStatus(PedestrianStatus event) {
    AppLogger.i("Pedestrian status: ${event.status}");
  }

  void _onStepCountError(dynamic error) {
    AppLogger.e("Step Count Error: $error");
  }

  void _onPedestrianStatusError(dynamic error) {
    AppLogger.e("Pedestrian Status Error: $error");
  }

  void stopTracking() {
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
  }
}
