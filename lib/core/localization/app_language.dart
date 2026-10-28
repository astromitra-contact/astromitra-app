enum AppLanguage {
  en(
    code: 'en',
    name: 'English',
    nativeName: 'English',
  ),
  hi(
    code: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
  ),
  gu(
    code: 'gu',
    name: 'Gujarati',
    nativeName: 'ગુજરાતી',
  ),
  mr(
    code: 'mr',
    name: 'Marathi',
    nativeName: 'मराठी',
  ),
  bn(
    code: 'bn',
    name: 'Bengali',
    nativeName: 'বাংলা',
  ),
  te(
    code: 'te',
    name: 'Telugu',
    nativeName: 'తెలుగు',
  ),
  ta(
    code: 'ta',
    name: 'Tamil',
    nativeName: 'தமிழ்',
  ),
  kn(
    code: 'kn',
    name: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
  ),
  ml(
    code: 'ml',
    name: 'Malayalam',
    nativeName: 'മലയാളം',
  ),
  pa(
    code: 'pa',
    name: 'Punjabi',
    nativeName: 'ਪੰਜਾਬੀ',
  );

  final String code;
  final String name;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
  });

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.en;
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.en,
    );
  }
}
