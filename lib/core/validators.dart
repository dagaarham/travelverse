/// Form validators shared by every screen. Each returns `null` when the value
/// is valid, or a user-friendly error message.
class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]{2,}$');
  static final RegExp _indianMobile = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _name = RegExp(r"^[a-zA-Z][a-zA-Z .'-]*$");

  static String? required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Full name is required';
    if (v.length < 3) return 'Name must be at least 3 characters';
    if (v.length > 40) return 'Name must be at most 40 characters';
    if (!_name.hasMatch(v)) return 'Name can contain only letters and spaces';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_email.hasMatch(v)) return 'Enter a valid email, e.g. name@example.com';
    return null;
  }

  /// 10-digit Indian mobile number, optionally prefixed with +91.
  static String? phone(String? value) {
    var v = (value ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (v.isEmpty) return 'Mobile number is required';
    if (v.startsWith('+91')) v = v.substring(3);
    if (!RegExp(r'^\d+$').hasMatch(v)) return 'Mobile number can contain only digits';
    if (v.length != 10) return 'Mobile number must be 10 digits';
    if (!_indianMobile.hasMatch(v)) return 'Enter a valid Indian mobile number starting with 6-9';
    return null;
  }

  /// At least 8 characters with an upper-case letter, a lower-case letter,
  /// a digit and a special character.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    if (v.length > 32) return 'Password must be at most 32 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add at least one capital letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add at least one small letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add at least one number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Add at least one special character (e.g. @, #, !)';
    return null;
  }

  /// Login only checks presence; strength rules apply at sign-up.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? text(String? value, String field, {int min = 1, int max = 500}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field is required';
    if (v.length < min) return '$field must be at least $min characters';
    if (v.length > max) return '$field must be at most $max characters';
    return null;
  }

  static String? optionalText(String? value, String field, {int max = 200}) {
    final v = value?.trim() ?? '';
    if (v.length > max) return '$field must be at most $max characters';
    return null;
  }

  /// Whole number between [min] and [max] inclusive.
  static String? intInRange(String? value, String field, {required int min, required int max}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$field is required';
    final n = int.tryParse(v);
    if (n == null) return '$field must be a whole number';
    if (n < min) return '$field must be at least $min';
    if (n > max) return '$field must be at most $max';
    return null;
  }

  /// Trip dates: both chosen, end not before start, trip at most 30 days,
  /// and start not in the past.
  static String? tripDates(DateTime? start, DateTime? end, {DateTime? today}) {
    if (start == null) return 'Select a start date';
    if (end == null) return 'Select an end date';
    final now = today ?? DateTime.now();
    final day0 = DateTime(now.year, now.month, now.day);
    if (start.isBefore(day0)) return 'Start date cannot be in the past';
    if (end.isBefore(start)) return 'End date must be on or after the start date';
    if (end.difference(start).inDays + 1 > 30) return 'A trip can be at most 30 days long';
    return null;
  }

  static String? rating(double? value, String field) {
    if (value == null || value < 1) return 'Please rate $field';
    if (value > 5) return '$field must be between 1 and 5';
    return null;
  }
}
