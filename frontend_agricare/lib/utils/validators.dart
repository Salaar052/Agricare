// ============================================
// FILE 9: lib/utils/validators.dart
// Form validators
// ============================================

class Validators {
  static String? Function(String?) required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }
}