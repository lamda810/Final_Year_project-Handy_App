import 'package:dio/dio.dart';
import '../../../core/error/exceptions.dart';
import '../../models/notification_model.dart';
import 'notification_remote_datasource.dart';

/// REST implementation of NotificationRemoteDataSource using Dio
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final Dio _dio;

  NotificationRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<NotificationsResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: {
          'page': page,
          'limit': limit,
          'unreadOnly': unreadOnly,
        },
      );
      return NotificationsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return (response.data['data']?['count'] ?? response.data['count'] ?? 0)
          as int;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/notifications/read-all');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> registerDevice({
    required String deviceToken,
    required String platform,
  }) async {
    try {
      await _dio.post(
        '/notifications/register-device',
        data: {
          'deviceToken': deviceToken,
          'platform': platform,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> unregisterDevice(String deviceToken) async {
    try {
      await _dio.delete(
        '/notifications/unregister-device',
        data: {'deviceToken': deviceToken},
      );
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
