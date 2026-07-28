/// Talks to the matching-service's AI assistant endpoint on behalf of
/// the worker app.
abstract class MatchingRepository {
  Future<Map<String, dynamic>> askAiAssistant({
    required String message,
    List<Map<String, String>>? conversationHistory,
  });
}
