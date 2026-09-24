import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/local_cache_service.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/kundli_models.dart';
import '../../data/repositories/kundli_repository.dart';

enum KundliLoadState { idle, loading, loaded, error }

/// Owns the on-device notion of "which Kundli(s) exist" and "which one is
/// active right now" — kundliId is the sole reference the backend
/// understands (no login/OTP), so this provider is effectively this app's
/// session state.
class KundliProvider extends ChangeNotifier {
  final KundliRepository _repository;
  final SecureStorageService _secureStorage;
  final LocalCacheService _localCache;

  KundliProvider({
    KundliRepository? repository,
    SecureStorageService? secureStorage,
    LocalCacheService? localCache,
  })  : _repository = repository ?? KundliRepository(),
        _secureStorage = secureStorage ?? SecureStorageService(),
        _localCache = localCache ?? LocalCacheService();

  KundliLoadState state = KundliLoadState.idle;
  String? errorMessage;

  String? activeKundliId;
  KundliData? activeKundliData;
  List<String> allKundliIds = [];

  bool get hasActiveKundli => activeKundliId != null;

  /// Called once at app start: restore whatever was on-device already, so
  /// returning users land on Home instead of Create Kundli again.
  Future<void> bootstrap() async {
    state = KundliLoadState.loading;
    notifyListeners();

    try {
      allKundliIds = await _secureStorage.getAllKundliIds();
      activeKundliId = await _secureStorage.getActiveKundliId();

      if (activeKundliId != null) {
        final cached = await _localCache.getCachedKundli(activeKundliId!);
        if (cached != null) {
          activeKundliData = KundliData.fromJson(cached);
        } else {
          // Cache missing (e.g. app data partially cleared) but the id
          // itself is still known — Home will show a lighter "chart
          // unavailable, but chat/credits still work" state rather than
          // losing the id entirely.
          activeKundliData = null;
        }
      }
      state = KundliLoadState.loaded;
    } catch (e) {
      state = KundliLoadState.error;
      errorMessage = 'Could not restore your saved Kundli.';
    }
    notifyListeners();
  }

  Future<KundliData> createKundli({
    required String name,
    required String dateOfBirth,
    String? timeOfBirth,
    required String birthPlace,
  }) async {
    state = KundliLoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.generateKundli(
        name: name,
        dateOfBirth: dateOfBirth,
        timeOfBirth: timeOfBirth,
        birthPlace: birthPlace,
      );

      if (result.kundliId == null) {
        // Backend generated the chart but couldn't persist it (e.g.
        // MongoDB not configured server-side) — the chart itself is
        // still valid and shown to the user, but Astro Chat/credits need
        // a kundliId to function, so this is surfaced clearly rather
        // than silently proceeding as if everything succeeded.
        throw const ApiException(
          message:
              'Your Kundli was calculated, but the server could not save it, so Astro Chat won\'t be available for it. Please try again shortly.',
          code: 'KUNDLI_NOT_STORED',
        );
      }

      await _secureStorage.setActiveKundliId(result.kundliId!);
      await _secureStorage.addKundliId(result.kundliId!);
      await _localCache.cacheKundli(result.kundliId!, result.toJson());

      activeKundliId = result.kundliId;
      activeKundliData = result;
      allKundliIds = await _secureStorage.getAllKundliIds();
      state = KundliLoadState.loaded;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      state = KundliLoadState.error;
      errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      state = KundliLoadState.error;
      errorMessage = 'Something went wrong while generating your Kundli.';
      notifyListeners();
      rethrow;
    }
  }

  Future<KundliData> updateKundli({
    required String kundliId,
    String? name,
    String? dateOfBirth,
    String? timeOfBirth,
    String? birthPlace,
  }) async {
    state = KundliLoadState.loading;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.updateKundli(
        kundliId: kundliId,
        name: name,
        dateOfBirth: dateOfBirth,
        timeOfBirth: timeOfBirth,
        birthPlace: birthPlace,
      );

      await _localCache.cacheKundli(kundliId, result.toJson());
      activeKundliId = kundliId;
      activeKundliData = result;
      state = KundliLoadState.loaded;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      state = KundliLoadState.error;
      errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      state = KundliLoadState.error;
      errorMessage = 'Something went wrong while updating your Kundli.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setActiveKundli(String kundliId) async {
    await _secureStorage.setActiveKundliId(kundliId);
    activeKundliId = kundliId;
    final cached = await _localCache.getCachedKundli(kundliId);
    activeKundliData = cached != null ? KundliData.fromJson(cached) : null;
    notifyListeners();
  }

  /// Permanently delete a Kundli from MongoDB and remove local caches.
  Future<void> deleteKundli(String kundliId) async {
    // 1. Delete on Backend (MongoDB)
    await _repository.deleteAccountData(kundliId);

    // 2. Remove locally
    await _secureStorage.removeKundliId(kundliId);
    await _localCache.removeCachedKundli(kundliId);
    await _localCache.saveChatHistory(kundliId, []);

    allKundliIds = await _secureStorage.getAllKundliIds();

    if (activeKundliId == kundliId) {
      await _secureStorage.clearActiveKundliId();
      activeKundliId = allKundliIds.isNotEmpty ? allKundliIds.last : null;
      if (activeKundliId != null) {
        await _secureStorage.setActiveKundliId(activeKundliId!);
        final cached = await _localCache.getCachedKundli(activeKundliId!);
        activeKundliData = cached != null ? KundliData.fromJson(cached) : null;
      } else {
        activeKundliData = null;
      }
    }
    notifyListeners();
  }

  /// Full wipe: Permanently deletes all Kundlis, UserCredits, and AI logs
  /// from the database (MongoDB), and clears all local secure storage and caches.
  Future<void> deleteAllLocalData() async {
    final idsToDelete = <String>{...allKundliIds};
    if (activeKundliId != null) {
      idsToDelete.add(activeKundliId!);
    }

    // 1. Wipe all data across all collections on the backend database
    for (final id in idsToDelete) {
      await _repository.deleteAccountData(id);
    }

    // 2. Wipe local storage and cache
    await _secureStorage.clearAll();
    for (final id in idsToDelete) {
      await _localCache.removeCachedKundli(id);
      await _localCache.saveChatHistory(id, []);
    }

    allKundliIds = [];
    activeKundliId = null;
    activeKundliData = null;
    notifyListeners();
  }
}
