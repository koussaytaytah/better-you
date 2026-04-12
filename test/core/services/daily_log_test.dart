import 'package:flutter_test/flutter_test.dart';
import 'package:better_you/shared/models/daily_log_model.dart';

void main() {
  group('DailyLog Health Score Calculation', () {
    test('Perfect health score should be 100', () {
      final log = DailyLog(
        id: '1',
        userId: 'u1',
        date: DateTime.now(),
        waterGlasses: 8,
        exerciseMinutes: 30,
        sleepHours: 8,
        steps: 10000,
        cigarettes: 0,
        alcohol: 0,
      );

      // 50 (base) + 20 (water) + 30 (exercise) + 20 (sleep) + 20 (steps) = 140 -> clamp to 100
      expect(log.calculateHealthScore(), 100);
    });

    test('Zero activity score should be 50', () {
      final log = DailyLog(
        id: '1',
        userId: 'u1',
        date: DateTime.now(),
        waterGlasses: 0,
        exerciseMinutes: 0,
        sleepHours: 0,
        steps: 0,
        cigarettes: 0,
        alcohol: 0,
      );

      expect(log.calculateHealthScore(), 50);
    });

    test('Unhealthy habits should decrease score', () {
      final log = DailyLog(
        id: '1',
        userId: 'u1',
        date: DateTime.now(),
        cigarettes: 5, // -50
        alcohol: 3,    // -30
      );

      // 50 (base) - 50 (cigs) - 30 (alcohol) = -30 -> clamp to 0
      expect(log.calculateHealthScore(), 0);
    });

    test('Partial activity should give partial score', () {
      final log = DailyLog(
        id: '1',
        userId: 'u1',
        date: DateTime.now(),
        waterGlasses: 4,     // +10
        exerciseMinutes: 15, // +15
        steps: 5000,        // +10
      );

      // 50 (base) + 10 + 15 + 10 = 85
      expect(log.calculateHealthScore(), 85);
    });
  });
}
