import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores the data that matters if it leaked: `kundliId` values. There's
/// no password/token in this app (no login system, per spec) — but a
/// `kundliId` is the sole key that identifies a person's birth chart and
/// spends their chat credits (see backend README), so it's treated as
/// sensitive and kept in the OS-level encrypted keystore/keychain rather
/// than plain SharedPreferences.
class SecureStorageService {
  static const _activeKundliIdKey = 'astromitra_active_kundli_id';
  static const _kundliIdListKey = 'astromitra_kundli_id_list';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  /// The Kundli currently in "active" use by Home/Astro Chat.
  Future<String?> getActiveKundliId() => _storage.read(key: _activeKundliIdKey);

  Future<void> setActiveKundliId(String kundliId) =>
      _storage.write(key: _activeKundliIdKey, value: kundliId);

  Future<void> clearActiveKundliId() => _storage.delete(key: _activeKundliIdKey);

  /// All Kundli ids ever created on this device (comma-separated — small,
  /// simple, and avoids pulling in a JSON codec for what's just a list of
  /// short ids). Supports someone generating more than one chart (e.g. for
  /// a family member) without losing track of earlier ones.
  Future<List<String>> getAllKundliIds() async {
    final raw = await _storage.read(key: _kundliIdListKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',').where((id) => id.isNotEmpty).toList();
  }

  Future<void> addKundliId(String kundliId) async {
    final existing = await getAllKundliIds();
    if (existing.contains(kundliId)) return;
    existing.add(kundliId);
    await _storage.write(key: _kundliIdListKey, value: existing.join(','));
  }

  Future<void> removeKundliId(String kundliId) async {
    final existing = await getAllKundliIds();
    existing.remove(kundliId);
    await _storage.write(key: _kundliIdListKey, value: existing.join(','));
  }

  /// Full wipe — used by Settings → Delete Account/Kundli.
  Future<void> clearAll() => _storage.deleteAll();
}
