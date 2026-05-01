abstract class MatchingRepository {
  Future<Map<String, dynamic>> askAiAssistant({
    required String message,
    String? city,
    String? area,
  });

  Future<Map<String, dynamic>> estimatePrice({
    required String serviceCategory,
    required String problemDescription,
    required String city,
    String? area,
    String? scheduledDateTime,
  });
}
