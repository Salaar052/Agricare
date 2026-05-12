// ============================================
// FILE 9: lib/utils/validators.dart
// Form validators
// ============================================

class Validators {
  static String _collapseSpaces(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _isSingleRepeatedChar(String value) {
    final noSpaces = value.replaceAll(RegExp(r'\s+'), '');
    if (noSpaces.isEmpty) return false;
    final first = noSpaces[0];
    for (final ch in noSpaces.split('')) {
      if (ch != first) return false;
    }
    return true;
  }

  static String? Function(String?) required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  static String? Function(String?) email({String fieldName = 'Email'}) {
    return (value) {
      final v = (value ?? '').trim();
      if (v.isEmpty) return '$fieldName is required';
      if (v.length > 254) return '$fieldName is too long';
      final normalized = v.toLowerCase();

      final re = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
      if (!re.hasMatch(normalized) || normalized.contains(' ') || normalized.contains('..')) {
        return 'Please enter a valid email address';
      }
      return null;
    };
  }

  static String? Function(String?) username({String fieldName = 'Username'}) {
    return (value) {
      final v0 = value ?? '';
      final v = _collapseSpaces(v0);
      if (v.isEmpty) return '$fieldName is required';
      if (v.length < 3) return '$fieldName must be at least 3 characters';
      if (v.length > 30) return '$fieldName must be 30 characters or less';

      final letterCount = RegExp(r'[A-Za-z]').allMatches(v).length;
      final alnumCount = RegExp(r'[A-Za-z0-9]').allMatches(v).length;
      if (alnumCount == 0) return '$fieldName cannot be only symbols';
      if (letterCount < 2) return 'Please enter a meaningful $fieldName (at least 2 letters)';
      if (_isSingleRepeatedChar(v)) return 'Please enter a meaningful $fieldName';

      return null;
    };
  }

  static String? Function(String?) loginPassword({int minLength = 6}) {
    return (value) {
      final v = value ?? '';
      if (v.trim().isEmpty) return 'Password is required';
      if (v.length < minLength) return 'Password must be at least $minLength characters';
      if (v.length > 128) return 'Password is too long';
      return null;
    };
  }

  static String? Function(String?) signupPassword() {
    return (value) {
      final v = value ?? '';
      if (v.isEmpty) return 'Password is required';
      if (v.length < 8) return 'Password must be at least 8 characters';
      if (v.length > 128) return 'Password is too long';
      if (RegExp(r'\s').hasMatch(v)) return 'Password cannot contain spaces';
      if (_isSingleRepeatedChar(v)) return 'Please choose a stronger password';

      final hasLetter = RegExp(r'[A-Za-z]').hasMatch(v);
      final hasNumber = RegExp(r'\d').hasMatch(v);
      if (!hasLetter || !hasNumber) {
        return 'Password must include at least 1 letter and 1 number';
      }

      const weak = {
        'password',
        'password123',
        '12345678',
        '123456789',
        'qwerty',
        'qwerty123',
        '11111111',
        '00000000',
      };
      if (weak.contains(v.toLowerCase())) {
        return 'Please choose a stronger password';
      }

      return null;
    };
  }
}