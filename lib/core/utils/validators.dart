/// Mirrors the backend's validation rules (see the backend's
/// `src/utils/validators.js`) so the form can show instant, specific
/// feedback instead of waiting on a round trip. This is a UX convenience
/// ONLY — the backend re-validates everything server-side regardless, and
/// remains the actual authority. Nothing here should ever be treated as a
/// security boundary.
class Validators {
  Validators._();

  static final RegExp _nameRegex = RegExp(r"^[\p{L}\p{M}\s.'-]+$", unicode: true);
  static final RegExp _placeRegex = RegExp(r"^[\p{L}\p{M}\p{N}\s,.'-]+$", unicode: true);
  static final RegExp _dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _timeRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length > 120) return 'Name must be 120 characters or fewer';
    if (!_nameRegex.hasMatch(v)) return 'Name contains invalid characters';
    return null;
  }

  static String? dateOfBirth(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Date of birth is required';
    if (!_dateRegex.hasMatch(v)) return 'Use YYYY-MM-DD format';
    final parsed = DateTime.tryParse(v);
    if (parsed == null) return 'Not a valid date';
    if (parsed.isAfter(DateTime.now())) return 'Date of birth cannot be in the future';
    if (parsed.year < 1800) return 'Date of birth must be on or after the year 1800';
    return null;
  }

  /// Time of birth is OPTIONAL on the backend (falls back to noon with a
  /// clearly-flagged approximation — see the Kundli result's
  /// `timeAccuracy` field). Empty is valid here; only a malformed
  /// non-empty value is rejected.
  static String? timeOfBirth(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (!_timeRegex.hasMatch(v)) return 'Use 24-hour HH:mm format';
    return null;
  }

  static String? birthPlace(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Birth place is required';
    if (v.length < 2 || v.length > 200) return 'Birth place must be 2-200 characters';
    if (!_placeRegex.hasMatch(v)) return 'Birth place contains invalid characters';
    return null;
  }

  static String? chatQuestion(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Type a question first';
    if (v.length < 3) return 'Question is too short';
    if (v.length > 1000) return 'Question must be 1000 characters or fewer';
    return null;
  }
}
