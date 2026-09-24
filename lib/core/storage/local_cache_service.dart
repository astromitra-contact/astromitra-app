import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Caches things that are convenient to keep locally but aren't secrets:
/// the last-fetched Kundli chart JSON (so "View Kundli" in Settings works
/// offline / without an extra network round trip — there is no
/// GET-by-id endpoint on the public API, only the response from
/// generate/update), and per-kundliId chat history ("maintain chat
/// history locally/session-wise", per spec).
///
/// Uses shared_preferences rather than flutter_secure_storage: these are
/// larger JSON blobs, not credentials, and secure storage is not designed
/// for that volume of data on all platforms.
class LocalCacheService {
  static const _kundliCachePrefix = 'astromitra_kundli_cache_';
  static const _chatHistoryPrefix = 'astromitra_chat_history_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> cacheKundli(String kundliId, Map<String, dynamic> kundliJson) async {
    final prefs = await _prefs;
    await prefs.setString('$_kundliCachePrefix$kundliId', jsonEncode(kundliJson));
  }

  Future<Map<String, dynamic>?> getCachedKundli(String kundliId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_kundliCachePrefix$kundliId');
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> removeCachedKundli(String kundliId) async {
    final prefs = await _prefs;
    await prefs.remove('$_kundliCachePrefix$kundliId');
    await removeChatHistory(kundliId);
  }

  /// Chat history is stored as a JSON array of {role, text, timestamp}.
  Future<void> saveChatHistory(String kundliId, List<Map<String, dynamic>> messages) async {
    final prefs = await _prefs;
    await prefs.setString('$_chatHistoryPrefix$kundliId', jsonEncode(messages));
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String kundliId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_chatHistoryPrefix$kundliId');
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  Future<void> removeChatHistory(String kundliId) async {
    final prefs = await _prefs;
    await prefs.remove('$_chatHistoryPrefix$kundliId');
  }

  /// Last time the daily rewarded-ad reward was claimed, used only to
  /// drive the UI's "already claimed today" hint optimistically before a
  /// network call — the backend's response remains the actual source of
  /// truth (see credit_provider.dart), never trusted for the real decision.
  Future<void> setLastRewardClaimHint(String kundliId, String isoDate) async {
    final prefs = await _prefs;
    await prefs.setString('astromitra_reward_hint_$kundliId', isoDate);
  }

  Future<String?> getLastRewardClaimHint(String kundliId) async {
    final prefs = await _prefs;
    return prefs.getString('astromitra_reward_hint_$kundliId');
  }
}
