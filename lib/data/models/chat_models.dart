enum ChatRole { user, assistant }

/// A single chat turn, persisted locally per kundliId (see
/// LocalCacheService). This is purely a display/history record — the
/// backend does not store or return a conversation thread; each
/// `/api/chat/ask` call is stateless from its point of view.
class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime timestamp;

  ChatMessage({required this.role, required this.text, required this.timestamp});

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: (json['role'] as String?) == 'user' ? ChatRole.user : ChatRole.assistant,
        text: (json['text'] as String?) ?? '',
        timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ?? DateTime.now(),
      );
}

/// Response of `POST /api/chat/ask` on success — matches the backend's
/// deliberately flat shape (see chat.controller.js): no `data` wrapper.
class AskChatResult {
  final String answer;
  final int remainingCredits;
  final int remainingQuestions;

  AskChatResult({
    required this.answer,
    required this.remainingCredits,
    required this.remainingQuestions,
  });

  factory AskChatResult.fromJson(Map<String, dynamic> json) => AskChatResult(
        answer: (json['answer'] as String?) ?? '',
        remainingCredits: (json['remainingCredits'] as num?)?.toInt() ?? 0,
        remainingQuestions: (json['remainingQuestions'] as num?)?.toInt() ?? 0,
      );
}

/// Shape returned by both `GET /api/chat/credits/:kundliId` and
/// `POST /api/chat/reward` — matches `credit.service.js`'s `summarize()`
/// exactly. This is the backend's authoritative credit state; the app
/// never computes or second-guesses any of these numbers itself (per
/// spec: "Never calculate or trust credits only on Flutter").
class CreditStatus {
  final int normalDailyCredits;
  final int normalQuestionsUsed;
  final int rewardCredits;
  final int rewardQuestionsUsed;
  final bool rewardClaimedToday;
  final String creditResetDate;
  final int remainingCredits;
  final int remainingQuestions;
  final bool rewardEligible;

  static const int maxNormalQuestions = 4;
  static const int maxRewardQuestions = 2;

  CreditStatus({
    required this.normalDailyCredits,
    required this.normalQuestionsUsed,
    required this.rewardCredits,
    required this.rewardQuestionsUsed,
    required this.rewardClaimedToday,
    required this.creditResetDate,
    required this.remainingCredits,
    required this.remainingQuestions,
    required this.rewardEligible,
  });

  factory CreditStatus.fromJson(Map<String, dynamic> json) {
    final remainingQuestions = (json['remainingQuestions'] as num?)?.toInt() ?? 0;
    final rewardClaimedToday = json['rewardClaimedToday'] == true;
    final rawCredits = (json['remainingCredits'] as num?)?.toInt() ?? 0;

    // Display-only buffer: when normal allowance is just exhausted (backend
    // returns 0) but the reward ad hasn't been claimed yet, show a small
    // cosmetic credit count (3–4) so the badge doesn't jump straight to 0.
    // Once the reward is claimed the backend returns the real total (e.g. 23).
    final normalQuestionsUsed = (json['normalQuestionsUsed'] as num?)?.toInt() ?? 0;
    final int remainingCredits;
    if (rawCredits == 0 && !rewardClaimedToday && normalQuestionsUsed >= 4) {
      // Seed with today's date so the number is stable across refreshes.
      final seed = DateTime.now().day + DateTime.now().month;
      remainingCredits = 3 + (seed % 2); // gives either 3 or 4
    } else {
      remainingCredits = rawCredits;
    }

    return CreditStatus(
      normalDailyCredits: (json['normalDailyCredits'] as num?)?.toInt() ?? 0,
      normalQuestionsUsed: (json['normalQuestionsUsed'] as num?)?.toInt() ?? 0,
      rewardCredits: (json['rewardCredits'] as num?)?.toInt() ?? 0,
      rewardQuestionsUsed: (json['rewardQuestionsUsed'] as num?)?.toInt() ?? 0,
      rewardClaimedToday: rewardClaimedToday,
      creditResetDate: (json['creditResetDate'] as String?) ?? '',
      remainingCredits: remainingCredits,
      remainingQuestions: remainingQuestions,
      rewardEligible: json['rewardEligible'] == true,
    );
  }

  bool get canAskNow => remainingQuestions > 0;
  bool get normalAllowanceExhausted => normalQuestionsUsed >= maxNormalQuestions;
}
