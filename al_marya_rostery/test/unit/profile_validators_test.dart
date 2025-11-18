import 'package:flutter_test/flutter_test.dart';

/// Validation functions matching EditProfilePage logic
class ProfileValidators {
  // Name validation - must be at least 2 characters
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Email validation - must match email regex pattern
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    // Same regex from EditProfilePage
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Phone validation - basic not empty check
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    return null;
  }

  // UAE Phone validation - supports multiple formats
  static String? validateUAEPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Support multiple UAE formats:
    // +971501234567, 971501234567, 0501234567, 501234567
    final patterns = [
      r'^\+971[0-9]{9}$', // +971501234567
      r'^971[0-9]{9}$', // 971501234567
      r'^0[0-9]{9}$', // 0501234567
      r'^[0-9]{9}$', // 501234567
    ];

    bool isValid = patterns.any(
      (pattern) => RegExp(pattern).hasMatch(cleanPhone),
    );

    if (!isValid) {
      return 'Please enter a valid UAE phone number';
    }

    return null;
  }
}

void main() {
  group('Profile Name Validation Tests', () {
    test('should return error for null name', () {
      expect(
        ProfileValidators.validateName(null),
        'Please enter your full name',
      );
    });

    test('should return error for empty name', () {
      expect(ProfileValidators.validateName(''), 'Please enter your full name');
    });

    test('should return error for whitespace-only name', () {
      expect(
        ProfileValidators.validateName('   '),
        'Please enter your full name',
      );
    });

    test('should return error for single character name', () {
      expect(
        ProfileValidators.validateName('A'),
        'Name must be at least 2 characters',
      );
    });

    test('should accept 2 character name', () {
      expect(ProfileValidators.validateName('AB'), isNull);
    });

    test('should accept valid full name', () {
      expect(ProfileValidators.validateName('Ahmed Al Mansouri'), isNull);
    });

    test('should accept name with special characters', () {
      expect(ProfileValidators.validateName("O'Connor-Smith"), isNull);
    });

    test('should accept very long names', () {
      expect(ProfileValidators.validateName('A' * 100), isNull);
    });

    test('should accept Arabic names', () {
      expect(ProfileValidators.validateName('أحمد المنصوري'), isNull);
    });
  });

  group('Profile Email Validation Tests', () {
    test('should return error for null email', () {
      expect(ProfileValidators.validateEmail(null), 'Please enter your email');
    });

    test('should return error for empty email', () {
      expect(ProfileValidators.validateEmail(''), 'Please enter your email');
    });

    test('should return error for whitespace-only email', () {
      expect(ProfileValidators.validateEmail('   '), 'Please enter your email');
    });

    test('should return error for invalid email format', () {
      expect(
        ProfileValidators.validateEmail('invalid-email'),
        'Please enter a valid email',
      );
    });

    test('should return error for email without domain', () {
      expect(
        ProfileValidators.validateEmail('user@'),
        'Please enter a valid email',
      );
    });

    test('should return error for email without @', () {
      expect(
        ProfileValidators.validateEmail('userexample.com'),
        'Please enter a valid email',
      );
    });

    test('should accept valid simple email', () {
      expect(ProfileValidators.validateEmail('user@example.com'), isNull);
    });

    test('should accept email with subdomain', () {
      expect(ProfileValidators.validateEmail('user@mail.example.com'), isNull);
    });

    test('should accept email with dots', () {
      expect(ProfileValidators.validateEmail('user.name@example.com'), isNull);
    });

    test('should accept email with dashes', () {
      expect(ProfileValidators.validateEmail('user-name@example.com'), isNull);
    });

    test('should accept email with numbers', () {
      expect(ProfileValidators.validateEmail('user123@example.com'), isNull);
    });
  });

  group('Profile Phone Validation Tests (Basic)', () {
    test('should return error for null phone', () {
      expect(
        ProfileValidators.validatePhone(null),
        'Please enter your phone number',
      );
    });

    test('should return error for empty phone', () {
      expect(
        ProfileValidators.validatePhone(''),
        'Please enter your phone number',
      );
    });

    test('should return error for whitespace-only phone', () {
      expect(
        ProfileValidators.validatePhone('   '),
        'Please enter your phone number',
      );
    });

    test('should accept any non-empty phone', () {
      expect(ProfileValidators.validatePhone('+971501234567'), isNull);
    });

    test('should accept formatted phone', () {
      expect(ProfileValidators.validatePhone('+971 50 123 4567'), isNull);
    });
  });

  group('Profile UAE Phone Validation Tests (Enhanced)', () {
    test('should return error for null phone', () {
      expect(
        ProfileValidators.validateUAEPhone(null),
        'Please enter your phone number',
      );
    });

    test('should return error for empty phone', () {
      expect(
        ProfileValidators.validateUAEPhone(''),
        'Please enter your phone number',
      );
    });

    test('should accept +971 format', () {
      expect(ProfileValidators.validateUAEPhone('+971501234567'), isNull);
    });

    test('should accept 971 format without plus', () {
      expect(ProfileValidators.validateUAEPhone('971501234567'), isNull);
    });

    test('should accept 0 prefix format', () {
      expect(ProfileValidators.validateUAEPhone('0501234567'), isNull);
    });

    test('should accept 9-digit format without prefix', () {
      expect(ProfileValidators.validateUAEPhone('501234567'), isNull);
    });

    test('should accept formatted phone with spaces', () {
      expect(ProfileValidators.validateUAEPhone('+971 50 123 4567'), isNull);
    });

    test('should accept formatted phone with dashes', () {
      expect(ProfileValidators.validateUAEPhone('+971-50-123-4567'), isNull);
    });

    test('should accept formatted phone with parentheses', () {
      expect(ProfileValidators.validateUAEPhone('+971 (50) 123-4567'), isNull);
    });

    test('should reject invalid UAE phone', () {
      expect(
        ProfileValidators.validateUAEPhone('123'),
        'Please enter a valid UAE phone number',
      );
    });

    test('should reject non-UAE country code', () {
      expect(
        ProfileValidators.validateUAEPhone('+1234567890'),
        'Please enter a valid UAE phone number',
      );
    });

    test('should reject too short number', () {
      expect(
        ProfileValidators.validateUAEPhone('12345'),
        'Please enter a valid UAE phone number',
      );
    });

    test('should reject letters in phone', () {
      expect(
        ProfileValidators.validateUAEPhone('+971abc123def'),
        'Please enter a valid UAE phone number',
      );
    });
  });

  group('Profile Form Completeness Tests', () {
    test('valid profile data should pass all validations', () {
      expect(ProfileValidators.validateName('Ahmed Al Mansouri'), isNull);
      expect(ProfileValidators.validateEmail('ahmed@example.com'), isNull);
      expect(ProfileValidators.validateUAEPhone('+971501234567'), isNull);
    });

    test('invalid profile data should fail validations', () {
      expect(ProfileValidators.validateName('A'), isNotNull);
      expect(ProfileValidators.validateEmail('invalid'), isNotNull);
      expect(ProfileValidators.validateUAEPhone('123'), isNotNull);
    });

    test('should handle mixed valid and invalid data', () {
      // Valid name, invalid email
      expect(ProfileValidators.validateName('Ahmed'), isNull);
      expect(ProfileValidators.validateEmail('invalid'), isNotNull);
    });
  });

  group('Profile Edge Cases', () {
    test('should handle extremely long email', () {
      final longEmail = '${'a' * 100}@${'b' * 100}.com';
      expect(ProfileValidators.validateEmail(longEmail), isNull);
    });

    test('should handle multiple dots in email', () {
      expect(
        ProfileValidators.validateEmail('user.name.test@example.co.uk'),
        isNull,
      );
    });

    test('should reject email with invalid TLD', () {
      expect(
        ProfileValidators.validateEmail('user@example.c'),
        'Please enter a valid email',
      );
    });

    test('should handle name with numbers', () {
      expect(ProfileValidators.validateName('Ahmed 123'), isNull);
    });

    test('should handle name with emojis', () {
      expect(ProfileValidators.validateName('Ahmed 😊'), isNull);
    });
  });
}
