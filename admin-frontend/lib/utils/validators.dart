class Validators {
  static final RegExp _emailRegex = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*$",
  );

  static final RegExp _phoneDigitsRegex = RegExp(r'^\+?[0-9]{8,15}$');

  static bool isValidEmail(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    return _emailRegex.hasMatch(v);
  }

  static bool isValidPhone(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return true;
    final normalized = raw.replaceAll(RegExp(r'[\s\-()]'), '');
    return _phoneDigitsRegex.hasMatch(normalized);
  }
}

