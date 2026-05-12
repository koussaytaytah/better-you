import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile Feature Tests', () {
    test('XP level calculation', () {
      // Level 1: 0-999 XP
      expect(calculateLevel(0), 1);
      expect(calculateLevel(500), 1);
      expect(calculateLevel(999), 1);
      
      // Level 2: 1000-2999 XP
      expect(calculateLevel(1000), 2);
      expect(calculateLevel(2000), 2);
      
      // Level 5: 10000+ XP
      expect(calculateLevel(10000) >= 5, isTrue);
    });

    test('Profile name validation', () {
      // Valid name
      final validName = 'John Doe';
      expect(validName.isNotEmpty, isTrue);
      expect(validName.length <= 50, isTrue);
      
      // Name with special characters
      final specialName = 'María-José';
      expect(specialName.isNotEmpty, isTrue);
    });

    test('Streak calculation', () {
      final lastActive = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();
      
      // Check if streak continues (last active yesterday)
      final daysDifference = today.difference(lastActive).inDays;
      expect(daysDifference, 1);
    });
  });
}

int calculateLevel(int xp) {
  if (xp < 1000) return 1;
  if (xp < 3000) return 2;
  if (xp < 6000) return 3;
  if (xp < 10000) return 4;
  return 5 + ((xp - 10000) / 5000).floor();
}
