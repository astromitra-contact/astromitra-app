import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/storage/local_cache_service.dart';
import '../../data/models/chat_models.dart';
import '../../data/repositories/chat_repository.dart';

/// Manages the Astro Chat conversation for the currently active Kundli.
/// Sends ONLY kundliId + question to the backend (per spec) — the backend
/// alone resolves birth chart, transit, and which AI provider answers.
/// History is kept locally per kundliId ("session-wise" persistence, per
/// spec) purely for display continuity; the backend has no concept of a
/// conversation thread.
class ChatProvider extends ChangeNotifier {
  final ChatRepository _repository;
  final LocalCacheService _localCache;

  ChatProvider({ChatRepository? repository, LocalCacheService? localCache})
      : _repository = repository ?? ChatRepository(),
        _localCache = localCache ?? LocalCacheService();

  String? _kundliId;
  List<ChatMessage> messages = [];
  bool isSending = false;
  bool isLoadingHistory = false;
  String? errorMessage;

  /// Set when the last failure was specifically "no allowance left" — the
  /// UI uses this to show the rewarded-ad option instead of a generic
  /// retry, per spec ("After normal allowance is exhausted, show
  /// rewarded-ad option").
  bool questionLimitReached = false;

  Future<void> loadForKundli(String kundliId) async {
    if (_kundliId == kundliId && messages.isNotEmpty) return;
    _kundliId = kundliId;
    isLoadingHistory = true;
    notifyListeners();

    final saved = await _localCache.getChatHistory(kundliId);
    messages = saved.map(ChatMessage.fromJson).toList();

    isLoadingHistory = false;
    notifyListeners();
  }

  Future<bool> sendQuestion(String kundliId, String question) async {
    questionLimitReached = false;
    errorMessage = null;

    final userMessage = ChatMessage(role: ChatRole.user, text: question, timestamp: DateTime.now());
    messages = [...messages, userMessage];
    isSending = true;
    notifyListeners();
    await _persist(kundliId);

    try {
      final result = await _repository.askQuestion(kundliId: kundliId, question: question);
      final chunks = _splitIntoConversationalChunks(result.answer);

      for (var i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        final assistantMessage = ChatMessage(
          role: ChatRole.assistant,
          text: chunk,
          timestamp: DateTime.now(),
        );
        messages = [...messages, assistantMessage];

        if (i < chunks.length - 1) {
          // Keep isSending = true so typing dots (...) show below the current bubble
          isSending = true;
          notifyListeners();
          final pauseMs = (750 + (chunk.length * 6).clamp(0, 450)).toInt();
          await Future.delayed(Duration(milliseconds: pauseMs));
        }
      }

      isSending = false;
      notifyListeners();
      await _persist(kundliId);
      return true;
    } on ApiException catch (e) {
      isSending = false;
      errorMessage = e.message;
      if (e.code == 'QUESTION_LIMIT_REACHED') {
        questionLimitReached = true;
      }
      notifyListeners();
      return false;
    } catch (e) {
      isSending = false;
      errorMessage = 'Could not send your question. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Splits an AI answer into natural, digestible conversational sentence chunks.
  List<String> _splitIntoConversationalChunks(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return [];

    final paragraphs = raw.split(RegExp(r'\n+'));
    final result = <String>[];

    for (final p in paragraphs) {
      final trimmed = p.trim();
      if (trimmed.isEmpty) continue;

      // Match sentences ending in punctuation
      final pattern = RegExp(r'[^.!?]+[.!?]+(?:\s+|$)|[^.!?]+$');
      final matches = pattern.allMatches(trimmed);
      final sentences = matches
          .map((m) => m.group(0)?.trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();

      String buffer = '';
      for (final s in sentences) {
        if (buffer.isEmpty) {
          buffer = s;
        } else if (buffer.length < 35 || s.length < 25) {
          // Merge very short fragments so sentences feel natural
          buffer = '$buffer $s';
        } else {
          result.add(buffer);
          buffer = s;
        }
      }
      if (buffer.isNotEmpty) {
        result.add(buffer);
      }
    }

    return result.isNotEmpty ? result : [raw];
  }

  Future<void> _persist(String kundliId) {
    return _localCache.saveChatHistory(kundliId, messages.map((m) => m.toJson()).toList());
  }

  Future<void> deleteMessage(ChatMessage message) async {
    messages = messages.where((m) => m != message).toList();
    notifyListeners();
    if (_kundliId != null) {
      await _persist(_kundliId!);
    }
  }

  Future<void> clearHistory(String kundliId) async {
    messages = [];
    errorMessage = null;
    questionLimitReached = false;
    isSending = false;
    notifyListeners();
    await _localCache.saveChatHistory(kundliId, []);
  }

  void clearError() {
    errorMessage = null;
    questionLimitReached = false;
    notifyListeners();
  }
}
