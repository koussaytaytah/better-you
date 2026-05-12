import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BMI Calculator Tests', () {
    double calculateBMI(double weightKg, double heightM) {
      return weightKg / (heightM * heightM);
    }

    String getBMICategory(double bmi) {
      if (bmi < 18.5) return 'Underweight';
      if (bmi < 25) return 'Normal';
      if (bmi < 30) return 'Overweight';
      return 'Obese';
    }

    test('BMI calculation for normal weight', () {
      // 70kg, 1.75m = 22.86 BMI
      final bmi = calculateBMI(70, 1.75);
      expect(bmi, closeTo(22.86, 0.01));
      expect(getBMICategory(bmi), 'Normal');
    });

    test('BMI calculation for underweight', () {
      // 50kg, 1.75m = 16.33 BMI
      final bmi = calculateBMI(50, 1.75);
      expect(bmi, closeTo(16.33, 0.01));
      expect(getBMICategory(bmi), 'Underweight');
    });

    test('BMI calculation for overweight', () {
      // 85kg, 1.75m = 27.76 BMI
      final bmi = calculateBMI(85, 1.75);
      expect(bmi, closeTo(27.76, 0.01));
      expect(getBMICategory(bmi), 'Overweight');
    });

    test('BMI calculation for obese', () {
      // 100kg, 1.75m = 32.65 BMI
      final bmi = calculateBMI(100, 1.75);
      expect(bmi, closeTo(32.65, 0.01));
      expect(getBMICategory(bmi), 'Obese');
    });

    test('BMI edge cases', () {
      // Exactly 18.5 should be Normal (boundary)
      expect(getBMICategory(18.5), 'Normal');
      
      // Exactly 25 should be Overweight (boundary)
      expect(getBMICategory(25), 'Overweight');
      
      // Exactly 30 should be Obese (boundary)
      expect(getBMICategory(30), 'Obese');
    });
  });
}
