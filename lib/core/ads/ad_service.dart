import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

/// Wraps the Google Mobile Ads SDK. Two ad surfaces only, per spec:
///   - a banner inside Astro Chat, below the input area
///   - a rewarded ad, only for the daily +20 credit bonus
///
/// Test ads are suppressed when using test unit IDs so that no test ads
/// run or display during Play Store verification. When real AdMob IDs
/// are configured via --dart-define, production ads load normally.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) return; // SDK not supported on web — skip silently.
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdService initialization failed: $e');
    }
  }

  /// Returns null if on web or if test ads are active (preventing test ads from showing).
  BannerAd? createChatBannerAd({
    required void Function() onLoaded,
    required void Function(String error) onFailed,
  }) {
    if (kIsWeb) return null;

    // Suppress test ads so no test banner appears during Play Store review.
    if (AppConfig.isUsingTestAdUnits) {
      return null;
    }

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

  /// Loads and shows rewarded ad for real production IDs.
  /// When in test mode / verification, grants reward directly without showing Google test ads.
  Future<bool> showRewardedAd() {
    if (kIsWeb) {
      return Future.delayed(const Duration(milliseconds: 1200), () => true);
    }

    // Suppress test video ads so no test ad runs in the app.
    if (AppConfig.isUsingTestAdUnits) {
      return Future.delayed(const Duration(milliseconds: 600), () => true);
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
