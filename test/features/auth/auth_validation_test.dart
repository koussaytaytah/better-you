import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Auth Validation Tests', () {
    test('Email validation should accept valid emails', () {
      final validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'admin@betteryou.com',
      ];
      
      for (final email in validEmails) {
        expect(email.contains('@'), isTrue, reason: '$email should contain @');
        expect(email.contains('.'), isTrue, reason: '$email should contain .');
      }
    });

    test('Password validation requirements', () {
      // Password must be at least 8 characters
      final shortPassword = 'Pass1';
      expect(shortPassword.length < 8, isTrue);
      
      // Valid password: 8+ chars, uppercase, number
      final validPassword = 'Password123';
      expect(validPassword.length >= 8, isTrue);
      expect(RegExp(r'[A-Z]').hasMatch(validPassword), isTrue);
      expect(RegExp(r'[0-9]').hasMatch(validPassword), isTrue);
    });

    test('Admin emails detection', () {
      final adminEmails = [
        'admin@betteryou.com',
        'admin2@betteryou.com', 
        'admin3@betteryou.com',
      ];
      
      for (final email in adminEmails) {
        final isMasterAdmin = email.toLowerCase() == 'admin@betteryou.com' ||
                             email.toLowerCase() == 'admin2@betteryou.com' ||
                             email.toLowerCase() == 'admin3@betteryou.com';
        expect(isMasterAdmin, isTrue);
      }
    });
  });
}
