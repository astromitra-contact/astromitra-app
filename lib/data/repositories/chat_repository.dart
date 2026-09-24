import '../../core/network/api_client.dart';
import '../models/chat_models.dart';

/// Talks only to the three existing `/api/chat/*` endpoints. Per spec,
/// `askQuestion` sends ONLY `kundliId` + `question` — the backend alone
/// resolves the birth chart, current transit, and which AI
/// provider/key answers (Gemini/Groq fallback). Nothing about that
/// pipeline is duplicated or second-guessed here.
class ChatRepository {
  final ApiClient _client;

  ChatRepository({ApiClient? client}) : _client = client ?? ApiClient();

  Future<AskChatResult> askQuestion({required String kundliId, required String question}) async {
    final json = await _client.post('/api/chat/ask', body: {
      'kundliId': kundliId,
      'question': question,
    });
    // This endpoint's success response is flat (no `data` wrapper) —
    // see chat.controller.js — so we parse `json` itself.
    return AskChatResult.fromJson(json);
  }

  Future<CreditStatus> claimReward({required String kundliId}) async {
    final json = await _client.post('/api/chat/reward', body: {'kundliId': kundliId});
    return CreditStatus.fromJson(json);
  }

  Future<CreditStatus> getCreditStatus({required String kundliId}) async {
    final json = await _client.get('/api/chat/credits/$kundliId');
    return CreditStatus.fromJson(json);
  }
}
