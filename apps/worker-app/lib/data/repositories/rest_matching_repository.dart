import 'package:dio/dio.dart';
import '../../domain/repositories/matching_repository.dart';
import '../../core/constants/api_endpoints.dart';

/// REST implementation of MatchingRepository for the Worker app.
class RestMatchingRepository implements MatchingRepository {
  final Dio _dio;

  RestMatchingRepository({required Dio dio}) : _dio = dio;

  @override
  Future<Map<String, dynamic>> askAiAssistant({
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.chatbotAsk,
      data: {
        'message': message,
        if (conversationHistory != null && conversationHistory.isNotEmpty)
          'conversationHistory': conversationHistory,
      },
    );
    return (response.data['data'] ?? response.data) as Map<String, dynamic>;
  }
}
