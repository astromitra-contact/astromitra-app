import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/app_config.dart';

/// Wraps the Google Mobile Ads SDK.
/// Supported Ad Formats:
///   - App Open Ad: Shown ONLY on first app open (during splash screen).
///   - Interstitial Ad: Shown when clicking Explore Now, Create Kundli, Chat, or Daily Horoscope.
///   - Banner Ad: Shown at top of Astro Chat screen.
///   - Rewarded Ad: Shown for daily +20 credit refill.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _initialized = false;

  // App Open Ad State (First app launch only)
  AppOpenAd? _appOpenAd;
  bool _isLoadingAppOpen = false;
  bool _isShowingAppOpen = false;
  DateTime? _appOpenLoadTime;
  Completer<void>? _appOpenLoadCompleter;

  // Interstitial Ad State
  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  Completer<void>? _interstitialLoadCompleter;

  // Rewarded Ad State
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;
  Completer<void>? _rewardedLoadCompleter;

  Future<void> initialize() async {
    if (kIsWeb) return; // SDK not supported on web — skip silently.
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdService initialized successfully');

      // Pre-load the first App Open Ad so it is ready on initial launch
      loadAppOpenAd();
      // Pre-load the first Interstitial Ad so it is ready for feature clicks
      loadInterstitialAd();
      // Pre-load the first Rewarded Ad so it is ready for bonus credits
      loadRewardedAd();
    } catch (e) {
      debugPrint('AdService initialization failed: $e');
    }
  }

  // ==========================================
  // APP OPEN AD METHODS
  // ==========================================

  /// Preloads an App Open Ad into memory.
  void loadAppOpenAd() {
    if (kIsWeb || _isLoadingAppOpen || isAppOpenAdAvailable) return;

    _isLoadingAppOpen = true;
    _appOpenLoadCompleter = Completer<void>();

    debugPrint('Loading AppOpenAd with unit ID: ${AppConfig.admobAppOpenUnitId}');
    AppOpenAd.load(
      adUnitId: AppConfig.admobAppOpenUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded successfully');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isLoadingAppOpen = false;
          if (_appOpenLoadCompleter?.isCompleted == false) {
            _appOpenLoadCompleter?.complete();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: ${error.message} (code ${error.code})');
          _appOpenAd = null;
          _isLoadingAppOpen = false;
          if (_appOpenLoadCompleter?.isCompleted == false) {
            _appOpenLoadCompleter?.complete();
          }
        },
      ),
    );
  }

  /// Whether a valid, non-expired App Open Ad is currently cached.
  /// AdMob App Open ads expire after 4 hours.
  bool get isAppOpenAdAvailable {
    return _appOpenAd != null &&
        _appOpenLoadTime != null &&
        DateTime.now().difference(_appOpenLoadTime!) < const Duration(hours: 4);
  }

  /// Shown during the initial launch (Splash Screen):
  /// Waits up to [timeout] for the ad to load if not yet ready, then displays it.
  /// Completes after the ad is dismissed, fails to show, or times out.
  Future<void> showAppOpenAdOnStart({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (kIsWeb) return;

    // If ad is currently loading, wait for it up to the timeout
    if (!isAppOpenAdAvailable && _isLoadingAppOpen) {
      try {
        await _appOpenLoadCompleter?.future.timeout(timeout);
      } catch (_) {
        // Timed out waiting for ad load — proceed gracefully
      }
    }

    if (isAppOpenAdAvailable) {
      final completer = Completer<void>();
      _showAppOpenAd(onDismissed: () {
        if (!completer.isCompleted) completer.complete();
      });
      await completer.future;
    } else {
      // Trigger background reload for subsequent view
      loadAppOpenAd();
    }
  }

  void _showAppOpenAd({VoidCallback? onDismissed}) {
    if (!isAppOpenAdAvailable || _isShowingAppOpen) {
      onDismissed?.call();
      return;
    }

    _isShowingAppOpen = true;
    final ad = _appOpenAd!;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('AppOpenAd presented full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AppOpenAd dismissed by user');
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpen = false;
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AppOpenAd failed to show: ${error.message}');
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpen = false;
        onDismissed?.call();
      },
    );

    ad.show();
  }

  // ==========================================
  // INTERSTITIAL AD METHODS
  // ==========================================

  /// Preloads an Interstitial Ad into memory.
  void loadInterstitialAd() {
    if (kIsWeb || _isLoadingInterstitial || _interstitialAd != null) return;
    _isLoadingInterstitial = true;
    _interstitialLoadCompleter = Completer<void>();

    debugPrint('Loading InterstitialAd with unit ID: ${AppConfig.admobInterstitialUnitId}');
    InterstitialAd.load(
      adUnitId: AppConfig.admobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('InterstitialAd loaded successfully');
          _interstitialAd = ad;
          _isLoadingInterstitial = false;
          if (_interstitialLoadCompleter?.isCompleted == false) {
            _interstitialLoadCompleter?.complete();
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: ${error.message} (code ${error.code})');
          _interstitialAd = null;
          _isLoadingInterstitial = false;
          if (_interstitialLoadCompleter?.isCompleted == false) {
            _interstitialLoadCompleter?.complete();
          }
        },
      ),
    );
  }

  /// Whether an Interstitial Ad is ready to show.
  bool get isInterstitialAdAvailable => _interstitialAd != null;

  /// Shows an Interstitial Ad before executing [onComplete].
  /// If the ad is ready, displays it and calls [onComplete] on dismiss.
  /// If currently loading, waits up to [timeout] (default 2 seconds).
  /// If no ad is ready, immediately executes [onComplete] without blocking navigation.
  Future<void> showInterstitialAd({
    required VoidCallback onComplete,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (kIsWeb) {
      onComplete();
      return;
    }

    if (_interstitialAd == null && _isLoadingInterstitial) {
      try {
        await _interstitialLoadCompleter?.future.timeout(timeout);
      } catch (_) {
        // Timed out waiting — continue to navigation
      }
    }

    if (_interstitialAd != null) {
      final ad = _interstitialAd!;
      _interstitialAd = null;

      final completer = Completer<void>();

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('InterstitialAd presented full screen');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('InterstitialAd dismissed by user');
          ad.dispose();
          loadInterstitialAd(); // Preload next
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('InterstitialAd failed to show: ${error.message}');
          ad.dispose();
          loadInterstitialAd();
          if (!completer.isCompleted) completer.complete();
        },
      );

      ad.show();
      await completer.future;
      onComplete();
    } else {
      loadInterstitialAd();
      onComplete();
    }
  }

  // ==========================================
  // BANNER AD METHODS
  // ==========================================

  /// Creates and loads a BannerAd for the Astro Chat screen.
  BannerAd? createChatBannerAd({
    required void Function() onLoaded,
    required void Function(String error) onFailed,
  }) {
    if (kIsWeb) return null;

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

  // ==========================================
  // REWARDED AD METHODS
  // ==========================================

  /// Preloads a Rewarded Ad into memory.
  void loadRewardedAd() {
    if (kIsWeb || _rewardedAd != null || _isLoadingRewarded) return;

    _isLoadingRewarded = true;
    _rewardedLoadCompleter = Completer<void>();

    RewardedAd.load(
      adUnitId: AppConfig.admobRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingRewarded = false;
          if (!(_rewardedLoadCompleter?.isCompleted ?? true)) {
            _rewardedLoadCompleter!.complete();
          }
          debugPrint('RewardedAd loaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          _rewardedAd = null;
          _isLoadingRewarded = false;
          if (!(_rewardedLoadCompleter?.isCompleted ?? true)) {
            _rewardedLoadCompleter!.complete();
          }
        },
      ),
    );
  }

  /// Loads and displays a RewardedAd for the daily credit refill (+20 credits).
  /// Waits up to [timeout] for the ad to load if not yet ready.
  /// Preloads the next ad immediately upon dismissal.
  Future<bool> showRewardedAd({Duration timeout = const Duration(seconds: 8)}) async {
    if (kIsWeb) {
      return Future.delayed(const Duration(milliseconds: 1200), () => true);
    }

    if (_rewardedAd == null && _isLoadingRewarded) {
      try {
        await _rewardedLoadCompleter?.future.timeout(timeout);
      } catch (_) {}
    }

    if (_rewardedAd == null) {
      loadRewardedAd();
      try {
        await _rewardedLoadCompleter?.future.timeout(timeout);
      } catch (_) {}
    }

    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not available');
      return false;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;

    final completer = _RewardCompleter();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('RewardedAd presented full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('RewardedAd dismissed by user');
        ad.dispose();
        loadRewardedAd(); // Immediately preload next
        completer.completeIfNotDone(completer.earnedReward);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('RewardedAd failed to show: ${error.message}');
        ad.dispose();
        loadRewardedAd();
        completer.completeIfNotDone(false);
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('User earned reward from RewardedAd');
        completer.earnedReward = true;
      },
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
