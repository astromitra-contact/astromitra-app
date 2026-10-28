import 'package:flutter/foundation.dart';

import '../../core/ads/ad_service.dart';
import '../../core/network/api_exception.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';

/// Holds this device's view of the ACTIVE Kundli's credit status. Every
/// number displayed comes directly from a backend response — this class
/// never adds, subtracts, or estimates a credit/question count itself
/// (per spec: "Never calculate or trust credits only on Flutter"). After
/// any action that could change credits (asking a question, claiming the
/// reward), it re-fetches the full authoritative status from the backend
/// rather than trying to patch fields locally.
class CreditProvider extends ChangeNotifier {
  final ChatRepository _repository;
  final AdService _adService;

  CreditProvider({ChatRepository? repository, AdService? adService})
      : _repository = repository ?? ChatRepository(),
        _adService = adService ?? AdService.instance;

  CreditStatus? status;
  bool isLoading = false;
  bool isClaimingReward = false;
  int completedAds = 0;
  String? errorMessage;

  Future<void> refresh(String kundliId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      status = await _repository.getCreditStatus(kundliId: kundliId);
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Could not load your current credits.';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Shows 2 rewarded ads sequentially; only after the user watches BOTH
  /// ads completely does this call the backend to grant the real +20 credits.
  /// Calls [onAdProgress] with (completedAds, totalAds) e.g. (1, 2).
  Future<RewardClaimOutcome> claimDailyReward(
    String kundliId, {
    void Function(int completedAds, int totalAds)? onAdProgress,
  }) async {
    isClaimingReward = true;
    completedAds = 0;
    errorMessage = null;
    notifyListeners();

    try {
      // Step 1: Show Ad 1 of 2
      onAdProgress?.call(0, 2);
      final ad1Earned = await _adService.showRewardedAd();
      if (!ad1Earned) {
        isClaimingReward = false;
        notifyListeners();
        return RewardClaimOutcome.adNotCompleted;
      }

      // Ad 1 completed
      completedAds = 1;
      onAdProgress?.call(1, 2);
      notifyListeners();

      // Brief delay to allow Android activity transition and ad reload
      await Future.delayed(const Duration(milliseconds: 700));

      // Step 2: Show Ad 2 of 2
      final ad2Earned = await _adService.showRewardedAd();
      if (!ad2Earned) {
        isClaimingReward = false;
        notifyListeners();
        return RewardClaimOutcome.adNotCompleted;
      }

      // Both ads completed! Claim the +20 credits from backend
      completedAds = 2;
      onAdProgress?.call(2, 2);
      notifyListeners();

      status = await _repository.claimReward(kundliId: kundliId);
      isClaimingReward = false;
      notifyListeners();
      return RewardClaimOutcome.success;
    } on ApiException catch (e) {
      isClaimingReward = false;
      errorMessage = e.message;
      notifyListeners();
      if (e.code == 'REWARD_ALREADY_CLAIMED') return RewardClaimOutcome.alreadyClaimed;
      if (e.code == 'NORMAL_ALLOWANCE_NOT_EXHAUSTED') return RewardClaimOutcome.notEligibleYet;
      return RewardClaimOutcome.error;
    } catch (e) {
      isClaimingReward = false;
      errorMessage = 'Could not claim your reward right now.';
      notifyListeners();
      return RewardClaimOutcome.error;
    }
  }
}

enum RewardClaimOutcome { success, adNotCompleted, alreadyClaimed, notEligibleYet, error }
