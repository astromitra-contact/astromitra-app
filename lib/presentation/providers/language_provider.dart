import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/app_language.dart';
import '../../core/localization/app_translations.dart';

class LanguageProvider extends ChangeNotifier {
  static const _prefKey = 'astromitra_selected_language';

  AppLanguage _currentLanguage = AppLanguage.en;
  bool _isInitialized = false;

  LanguageProvider() {
    init();
  }

  AppLanguage get currentLanguage => _currentLanguage;
  bool get isInitialized => _isInitialized;

  /// Translates a given translation key into the active language.
  String t(String key, [Map<String, String>? params]) {
    return AppTranslations.get(key, _currentLanguage, params);
  }

  /// Initialize and load persisted language from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && savedCode.isNotEmpty) {
        _currentLanguage = AppLanguage.fromCode(savedCode);
      }
    } catch (_) {
      _currentLanguage = AppLanguage.en;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Changes the app language and persists the choice.
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language.code);
    } catch (_) {
      // SharedPreferences failure is non-fatal for session
    }
  }
}

/// Convenience extensions on [BuildContext] for cleaner code throughout the UI.
extension LanguageContextExtension on BuildContext {
  LanguageProvider get langProvider => watch<LanguageProvider>();

  AppLanguage get currentLanguage => watch<LanguageProvider>().currentLanguage;

  String tr(String key, [Map<String, String>? params]) =>
      watch<LanguageProvider>().t(key, params);
}
