class Validators {
  static String? notEmpty(String? value, {String? fieldName, String Function(String, [Map<String, String>?])? tr}) {
    if (value == null || value.trim().isEmpty) {
      if (tr != null) {
        return tr('field_required', {'field': fieldName ?? ''});
      }
      return '$fieldName is required.';
    }
    return null;
  }

  static String? email(String? value, {String Function(String, [Map<String, String>?])? tr}) {
    if (value == null || value.trim().isEmpty) {
      return tr != null ? tr('email_required') : 'Email is required.';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return tr != null ? tr('invalid_email') : 'Enter a valid email address.';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, {String Function(String, [Map<String, String>?])? tr}) {
    if (value == null || value.length < minLength) {
      return tr != null ? tr('password_min_length') : 'Must be at least $minLength characters.';
    }
    return null;
  }

  static String? password(String? value, {String Function(String, [Map<String, String>?])? tr}) {
    final error = minLength(value, 8, tr: tr);
    if (error != null) return error;
    if (!RegExp(r'[A-Z]').hasMatch(value!)) {
      return tr != null ? tr('password_uppercase') : 'Password must contain an uppercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return tr != null ? tr('password_number') : 'Password must contain a number.';
    }
    return null;
  }
}
