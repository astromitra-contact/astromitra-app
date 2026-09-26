
/// Central runtime configuration. Nothing secret lives here — the backend
/// base URL is a plain endpoint address, not a credential, and every value
/// below is overridable at build time via `--dart-define` so the same code
/// works for local development, staging, and production without editing
/// source.
///
/// Example release build:
///   flutter build apk --release \
///     --dart-define=API_BASE_URL=https://api.astromitra.com \
///     --dart-define=ADMOB_APP_ID=ca-app-pub-xxxxxxxxxxxxxxxx~yyyyyyyyyy \
///     --dart-define=ADMOB_BANNER_UNIT_ID=ca-app-pub-xxxxxxxxxxxxxxxx/zzzzzzzzzz \
///     --dart-define=ADMOB_REWARDED_UNIT_ID=ca-app-pub-xxxxxxxxxxxxxxxx/wwwwwwwwww
class AppConfig {
  AppConfig._();

  /// Compile-time override via --dart-define=API_BASE_URL=...
  /// Defaults to the Android emulator alias. Use [resolvedApiBaseUrl] at
  /// runtime so the correct default is picked for each platform.
  static const String _apiBaseUrlEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://astromitra-kundliapi.onrender.com',
  );

  /// Runtime-resolved backend base URL.
  ///   - If --dart-define=API_BASE_URL was provided, that value is always used.
  ///   - Defaults to https://astromitra-kundliapi.onrender.com
  static String get apiBaseUrl {
    if (_apiBaseUrlEnv.isNotEmpty) return _apiBaseUrlEnv;
    return 'https://astromitra-kundliapi.onrender.com';
  }

  static const Duration requestTimeout = Duration(seconds: 20);
  static const int maxRetries = 2;

  /// AdMob IDs. These are NOT secret credentials in the way an API key is
  /// (they identify an ad placement, not grant backend access), but they
  /// are still per-app/per-publisher and must never be a stranger's ID in
  /// a shipped app. Defaults below are Google's own published TEST IDs —
  /// safe to ship during development, but MUST be replaced with your own
  /// real AdMob IDs (via --dart-define, see above, and in
  /// android/app/src/main/AndroidManifest.xml) before a Play Store release.
  /// See https://developers.google.com/admob/android/test-ads
  static const String admobAppId = String.fromEnvironment(
    'ADMOB_APP_ID',
    defaultValue: 'ca-app-pub-3940256099942544~3347511713', // Google test App ID
  );

  static const String admobBannerUnitId = String.fromEnvironment(
    'ADMOB_BANNER_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/6300978111', // Google test banner unit
  );

  static const String admobRewardedUnitId = String.fromEnvironment(
    'ADMOB_REWARDED_UNIT_ID',
    defaultValue: 'ca-app-pub-3940256099942544/5224354917', // Google test rewarded unit
  );

  /// True when still using Google's published test ad unit IDs (i.e. no
  /// real IDs were supplied at build time). Used to show a small "TEST
  /// ADS" indicator in debug builds so nobody accidentally ships to
  /// production still on test IDs without noticing.
  static bool get isUsingTestAdUnits =>
      admobBannerUnitId == 'ca-app-pub-3940256099942544/6300978111';
}
