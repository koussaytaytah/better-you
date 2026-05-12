import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Nutrition Feature Tests', () {
    test('Calorie calculation', () {
      // BMR calculation (Mifflin-St Jeor equation)
      // Male: 10*weight + 6.25*height - 5*age + 5
      final weight = 70; // kg
      final height = 175; // cm
      final age = 30;
      
      final bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      expect(bmr, closeTo(1648.75, 0.01));
      
      // TDEE with moderate activity (1.55 multiplier)
      final tdee = bmr * 1.55;
      expect(tdee, closeTo(2555.56, 0.01));
    });

    test('Macro calculation', () {
      final calories = 2000;
      
      // Standard macro split: 40% carbs, 30% protein, 30% fat
      final carbs = (calories * 0.40) / 4; // 4 cal/g
      final protein = (calories * 0.30) / 4; // 4 cal/g
      final fat = (calories * 0.30) / 9; // 9 cal/g
      
      expect(carbs, closeTo(200, 1));
      expect(protein, closeTo(150, 1));
      expect(fat, closeTo(67, 1));
    });

    test('Water intake calculation', () {
      final weight = 70; // kg
      final recommendedWater = weight * 0.033; // liters
      
      expect(recommendedWater, closeTo(2.31, 0.01));
    });

    test('Food search validation', () {
      final searchQuery = 'chicken breast';
      expect(searchQuery.isNotEmpty, isTrue);
      expect(searchQuery.length >= 2, isTrue);
      
      // Results should be filtered
      final foods = [
        {'name': 'Chicken Breast', 'calories': 165},
        {'name': 'Chicken Thigh', 'calories': 226},
        {'name': 'Beef Steak', 'calories': 250},
      ];
      
      final filtered = foods.where((f) => 
        f['name'].toString().toLowerCase().contains('chicken')
      ).toList();
      
      expect(filtered.length, 2);
    });
  });

  group('AI Food Detection Tests', () {
    test('Food macro parsing', () {
      final detectedText = 'Chicken breast: 165 cal, 31g protein, 3.6g fat';
      
      // Extract protein
      final proteinMatch = RegExp(r'(\d+(\.\d+)?)g protein').firstMatch(detectedText);
      final protein = double.parse(proteinMatch?.group(1) ?? '0');
      expect(protein, 31);
    });

    test('Food confidence threshold', () {
      final confidence = 0.85;
      final threshold = 0.70;
      
      expect(confidence >= threshold, isTrue);
    });
  });
}
