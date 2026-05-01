import 'package:dio/dio.dart';
import '../../core/error/exceptions.dart';
import '../../domain/repositories/matching_repository.dart';

class MatchingRepositoryImpl implements MatchingRepository {
  final Dio _dio;

  MatchingRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Map<String, dynamic>> askAiAssistant({
    required String message,
    String? city,
    String? area,
  }) async {
    try {
      final response = await _dio.post(
        '/matching/chatbot/ask',
        data: {
          'message': message,
          'contextData': {
            if (city != null) 'city': city,
            if (area != null) 'area': area,
          },
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> estimatePrice({
    required String serviceCategory,
    required String problemDescription,
    required String city,
    String? area,
    String? scheduledDateTime,
  }) async {
    try {
      final response = await _dio.post(
        '/matching/estimate-price',
        data: {
          'serviceCategory': serviceCategory,
          'problemDescription': problemDescription,
          'location': {
            'city': city,
            if (area != null) 'area': area,
          },
          if (scheduledDateTime != null) 'scheduledDateTime': scheduledDateTime,
        },
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      final message = data is Map ? data['message'] ?? 'Server error' : 'Server error';
      return ServerException(
        message: message,
        statusCode: e.response!.statusCode,
        data: data,
      );
    }
    return const ServerException(message: 'Unexpected network error');
  }
}
