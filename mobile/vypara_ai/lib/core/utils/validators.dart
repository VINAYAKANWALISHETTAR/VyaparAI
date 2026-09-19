class Validators {
  static String? notEmpty(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? minLength(String? value, int minLength) {
    if (value == null || value.length < minLength) {
      return 'Must be at least $minLength characters.';
    }
    return null;
  }

  static String? password(String? value) {
    final error = minLength(value, 8);
    if (error != null) return error;
    if (!RegExp(r'[A-Z]').hasMatch(value!)) {
      return 'Password must contain an uppercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number.';
    }
    return null;
  }
}
