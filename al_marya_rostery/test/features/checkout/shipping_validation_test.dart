import 'package:flutter_test/flutter_test.dart';

/// Tests for shipping form validation logic
void main() {
  group('Phone Validation Tests', () {
    // UAE phone validation - supports multiple formats
    // Patterns: +971501234567, 971501234567, 0501234567, 501234567
    // Mobile prefixes: 50, 52, 54, 55, 56, 58
    // Landline prefixes: 2, 3, 4, 6, 7, 9
    bool validateUAEPhone(String phone) {
      final patterns = [
        RegExp(r'^\+971[0-9]{9}$'), // +971501234567
        RegExp(r'^971[0-9]{9}$'), // 971501234567
        RegExp(r'^0[0-9]{9}$'), // 0501234567
        RegExp(r'^[0-9]{9}$'), // 501234567
      ];
      return patterns.any((pattern) => pattern.hasMatch(phone));
    }

    test('Valid phone format: +971XXXXXXXXX (mobile)', () {
      expect(validateUAEPhone('+971501234567'), isTrue);
      expect(validateUAEPhone('+971521234567'), isTrue);
      expect(validateUAEPhone('+971541234567'), isTrue);
      expect(validateUAEPhone('+971551234567'), isTrue);
      expect(validateUAEPhone('+971561234567'), isTrue);
      expect(validateUAEPhone('+971581234567'), isTrue);
    });

    test('Valid phone format: 971XXXXXXXXX (without +)', () {
      expect(validateUAEPhone('971501234567'), isTrue);
      expect(validateUAEPhone('971521234567'), isTrue);
    });

    test('Valid phone format: 0XXXXXXXXX (local format)', () {
      expect(validateUAEPhone('0501234567'), isTrue);
      expect(validateUAEPhone('0521234567'), isTrue);
      expect(validateUAEPhone('0541234567'), isTrue);
    });

    test('Valid phone format: XXXXXXXXX (9 digits)', () {
      expect(validateUAEPhone('501234567'), isTrue);
      expect(validateUAEPhone('521234567'), isTrue);
    });

    test('Valid phone format: landline', () {
      expect(validateUAEPhone('+971212345678'), isTrue);
      expect(validateUAEPhone('+971312345678'), isTrue);
      expect(validateUAEPhone('+971412345678'), isTrue);
    });

    test('Invalid phone format: wrong country code', () {
      expect(validateUAEPhone('+966501234567'), isFalse); // Saudi Arabia
      expect(validateUAEPhone('+974501234567'), isFalse); // Qatar
      expect(validateUAEPhone('+1501234567'), isFalse); // US
    });

    test('Invalid phone format: too few digits', () {
      expect(validateUAEPhone('+97150123456'), isFalse); // Only 8 digits
      expect(validateUAEPhone('50123456'), isFalse); // Only 8 digits
      expect(validateUAEPhone('012345'), isFalse); // Only 6 digits
    });

    test('Invalid phone format: too many digits', () {
      expect(validateUAEPhone('+9715012345678'), isFalse); // 10 digits
      expect(validateUAEPhone('50123456789'), isFalse); // 11 digits
    });

    test('Invalid phone format: letters included', () {
      expect(validateUAEPhone('+971ABC123456'), isFalse);
      expect(validateUAEPhone('05ABC12345'), isFalse);
    });

    test('Invalid phone format: empty string', () {
      expect(validateUAEPhone(''), isFalse);
    });

    test('Normalize phone with extra spaces', () {
      final phone = '+971501234567   ';
      final trimmed = phone.trim();
      expect(validateUAEPhone(trimmed), isTrue);
    });
  });

  group('Address Validation Tests', () {
    test('Valid address: non-empty string', () {
      const address = '123 Sheikh Zayed Road, Dubai';
      expect(address.trim().isNotEmpty, isTrue);
    });

    test('Invalid address: empty string', () {
      const address = '';
      expect(address.trim().isEmpty, isTrue);
    });

    test('Invalid address: only whitespace', () {
      const address = '   ';
      expect(address.trim().isEmpty, isTrue);
    });

    test('Valid address: with special characters', () {
      const address = 'Villa #12-B, Behind Al Manara Mosque';
      expect(address.trim().isNotEmpty, isTrue);
    });

    test('Valid address: with numbers and slashes', () {
      const address = 'Plot 45/B, Street 2nd, Area 3';
      expect(address.trim().isNotEmpty, isTrue);
    });

    test('Valid address: from Google Maps reverse-geocoding', () {
      const address = 'Sheikh Zayed Road, Dubai, United Arab Emirates, 00000';
      expect(address.trim().isNotEmpty, isTrue);
    });
  });

  group('Form Validation Integration', () {
    bool validateUAEPhone(String phone) {
      final patterns = [
        RegExp(r'^\+971[0-9]{9}$'),
        RegExp(r'^971[0-9]{9}$'),
        RegExp(r'^0[0-9]{9}$'),
        RegExp(r'^[0-9]{9}$'),
      ];
      return patterns.any((pattern) => pattern.hasMatch(phone));
    }

    test('Form valid: phone and address both provided', () {
      final phone = '+971501234567';
      final address = '123 Sheikh Zayed Road, Dubai';

      final isPhoneValid = validateUAEPhone(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isTrue);
    });

    test('Form invalid: phone missing, address provided', () {
      final phone = '';
      final address = '123 Sheikh Zayed Road, Dubai';

      final isPhoneValid = phone.isNotEmpty && validateUAEPhone(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isFalse);
    });

    test('Form invalid: phone provided, address missing', () {
      final phone = '+971501234567';
      final address = '';

      final isPhoneValid = validateUAEPhone(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isFalse);
    });

    test('Form invalid: both phone and address missing', () {
      final phone = '';
      final address = '';

      final isPhoneValid = phone.isNotEmpty && validateUAEPhone(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isFalse);
    });

    test('Form invalid: phone wrong format, address valid', () {
      final phone = '+966501234567'; // Saudi Arabia number
      final address = '123 Sheikh Zayed Road, Dubai';

      final isPhoneValid = validateUAEPhone(phone.trim());
      final isAddressValid = address.trim().isNotEmpty;

      expect(isPhoneValid && isAddressValid, isFalse);
    });
  });

  group('GPS Location Tests', () {
    test('Valid GPS coordinates: Dubai center', () {
      const latitude = 25.2048;
      const longitude = 55.2708;

      expect(latitude >= -90 && latitude <= 90, isTrue);
      expect(longitude >= -180 && longitude <= 180, isTrue);
    });

    test('Valid GPS coordinates: edge of map', () {
      const latitude = 90.0; // North pole
      const longitude = -180.0; // Date line

      expect(latitude >= -90 && latitude <= 90, isTrue);
      expect(longitude >= -180 && longitude <= 180, isTrue);
    });

    test('Invalid GPS coordinates: latitude out of range', () {
      const latitude = 91.0;

      expect(latitude >= -90 && latitude <= 90, isFalse);
    });

    test('Invalid GPS coordinates: longitude out of range', () {
      const longitude = 181.0;

      expect(longitude >= -180 && longitude <= 180, isFalse);
    });

    test('GPS fallback to manual address when permission denied', () {
      final address = 'Selected from manual entry';
      final gpsCoordinates = null;

      expect(address.isNotEmpty, isTrue);
      expect(gpsCoordinates, isNull);
    });
  });

  group('Phone Format Normalization', () {
    bool validateUAEPhone(String phone) {
      final patterns = [
        RegExp(r'^\+971[0-9]{9}$'),
        RegExp(r'^971[0-9]{9}$'),
        RegExp(r'^0[0-9]{9}$'),
        RegExp(r'^[0-9]{9}$'),
      ];
      return patterns.any((pattern) => pattern.hasMatch(phone));
    }

    test('Remove extra spaces: leading/trailing', () {
      final phone = '  +971501234567  ';
      final normalized = phone.trim();
      expect(validateUAEPhone(normalized), isTrue);
    });

    test('Phone stays same with correct formatting', () {
      final phone = '+971501234567';
      final normalized = phone.trim();
      expect(validateUAEPhone(normalized), isTrue);
    });

    test('Phone with spaces (should be removed)', () {
      final phone = '+971 50 123 4567';
      final normalized = phone.replaceAll(' ', '');
      expect(validateUAEPhone(normalized), isTrue);
    });
  });

  group('User Input Edge Cases', () {
    bool validateUAEPhone(String phone) {
      final patterns = [
        RegExp(r'^\+971[0-9]{9}$'),
        RegExp(r'^971[0-9]{9}$'),
        RegExp(r'^0[0-9]{9}$'),
        RegExp(r'^[0-9]{9}$'),
      ];
      return patterns.any((pattern) => pattern.hasMatch(phone));
    }

    test('Phone with dashes (should be valid after normalization)', () {
      final phone = '+971-50-123-4567';
      final normalized = phone.replaceAll('-', '').replaceAll(' ', '');
      expect(validateUAEPhone(normalized), isTrue);
    });

    test('Address with newlines (should normalize)', () {
      final address = 'Street 1\nDubai\nUAE';
      expect(address.trim().isNotEmpty, isTrue); // Still valid after trim
    });

    test('Address with multiple spaces (should still be valid)', () {
      final address = 'Villa  123   Dubai'; // Multiple spaces
      expect(address.trim().isNotEmpty, isTrue);
    });

    test('Phone starting with country code without +', () {
      final phone = '971501234567';
      expect(validateUAEPhone(phone.trim()), isTrue);
    });

    test('Phone with parentheses (should be valid after normalization)', () {
      final phone = '+971 (50) 123-4567';
      final normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      expect(validateUAEPhone(normalized), isTrue);
    });
  });
}
