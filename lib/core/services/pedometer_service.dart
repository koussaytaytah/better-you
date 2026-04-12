import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/daily_log_repository.dart';
import '../../shared/providers/data_provider.dart';
import '../../shared/providers/auth_provider.dart';
import 'package:logger/logger.dart';

final pedometerServiceProvider = Provider<PedometerService>((ref) {
  return PedometerService(ref);
});

class PedometerService {
  final Ref _ref;
  StreamSubscription<StepCount>? _stepCountStream;
  final _logger = Logger();
  int _lastBaselineSteps = 0;
  bool _isInit = false;

  PedometerService(this._ref);

  Future<void> init() async {
    if (_isInit) return;
    
    if (await Permission.activityRecognition.request().isGranted) {
      _initPedometer();
    } else {
      _logger.w('Pedometer Service: Activity Recognition permission denied.');
    }
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
      cancelOnError: false,
    );
    _isInit = true;
    _logger.i('Pedometer Service initialized successfully.');
  }

  void _onStepCount(StepCount event) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    // The pedometer package returns the total steps since the phone booted.
    // We need to calculate steps taken *today*.
    // For simplicity, we track the baseline upon app launch.
    if (_lastBaselineSteps == 0 || _lastBaselineSteps > event.steps) {
       _lastBaselineSteps = event.steps;
       return;
    }
    
    final int sessionSteps = event.steps - _lastBaselineSteps;
    _lastBaselineSteps = event.steps;

    try {
      final todayLog = await _ref.read(todayLogProvider.future);
      if (todayLog != null && sessionSteps > 0) {
        final currentSteps = todayLog.steps ?? 0;
        await _ref.read(dailyLogRepositoryProvider).updateDailyLog(
          user.uid,
          DateTime.now(),
          {
            'steps': currentSteps + sessionSteps,
          },
        );
      }
    } catch(e) {
      _logger.e('Failed to sync auto-steps: $e');
    }
  }

  void _onStepCountError(error) {
    _logger.e('Pedometer Stream Error: $error');
  }

  void dispose() {
    _stepCountStream?.cancel();
    _isInit = false;
  }
}
