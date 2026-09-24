import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

/// Wraps the Google Mobile Ads SDK. Two ad surfaces only, per spec:
///   - a banner inside Astro Chat, below the input area
///   - a rewarded ad, only for the daily +20 credit bonus
///
/// No interstitials, no ads anywhere else in the app. Ad unit IDs come
/// entirely from [AppConfig] (itself sourced from --dart-define, never
/// hardcoded here) — see that file's doc comment for how to supply real
/// production IDs.
///
/// NOTE: google_mobile_ads has no web implementation. All methods return
/// no-ops on web so the app boots correctly in a browser.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return; // SDK not supported on web — skip silently.
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// Returns null on web (caller must guard before using the result).
  BannerAd? createChatBannerAd({
    required void Function() onLoaded,
    required void Function(String error) onFailed,
  }) {
    if (kIsWeb) return null; // Not supported on web.
    final ad = BannerAd(
      adUnitId: AppConfig.admobBannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onFailed(error.message);
        },
      ),
    );
    ad.load();
    return ad;
  }

  /// Loads and immediately shows a rewarded ad. Resolves `true` only if
  /// the user actually earned the reward (watched it through) — the
  /// caller (credit_provider.dart) then calls the backend's
  /// `POST /api/chat/reward` as the real, authoritative grant of credits.
  /// This client-side "earned" signal is never itself treated as having
  /// granted anything — it only gates whether we bother calling the
  /// backend at all.
  ///
  /// On web (where Google Mobile Ads SDK is unavailable), simulates a completed ad
  /// so development & testing can proceed in the browser.
  Future<bool> showRewardedAd() {
    if (kIsWeb) {
      return Future.delayed(const Duration(milliseconds: 1200), () => true);
    }

    final completer = _RewardCompleter();

    RewardedAd.load(
      adUnitId: AppConfig.admobRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              completer.completeIfNotDone(completer.earnedReward);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              completer.completeIfNotDone(false);
            },
          );
          ad.show(
            onUserEarnedReward: (ad, reward) {
              completer.earnedReward = true;
            },
          );
        },
        onAdFailedToLoad: (error) {
          completer.completeIfNotDone(false);
        },
      ),
    );

    return completer.future;
  }
}

/// Small helper so we never call `complete()` twice on the same Completer
/// (which throws) across the several async callback paths a rewarded ad
/// can take (dismissed / failed to show / failed to load).
class _RewardCompleter {
  final _completer = Completer<bool>();
  bool _done = false;
  bool earnedReward = false;

  Future<bool> get future => _completer.future;

  void completeIfNotDone(bool value) {
    if (_done) return;
    _done = true;
    _completer.complete(value);
  }
}
