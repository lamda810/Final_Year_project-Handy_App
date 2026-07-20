import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/error/exceptions.dart';
import '../../models/auth_response_model.dart';
import 'auth_remote_datasource.dart';

/// REST implementation of AuthRemoteDataSource using Dio
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<OTPSendResponse> sendOTP({
    required String email,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.sendOTP,
        data: {
          'email': email,
          'purpose': purpose,
        },
      );

      return OTPSendResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OTPVerificationResult> verifyOTP({
    required String email,
    required String code,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyOTP,
        data: {
          'email': email,
          'code': code,
          'purpose': purpose,
        },
      );

      return OTPVerificationResult.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> register({
    required String tempToken,
    required String firstName,
    required String lastName,
    String? phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerCustomer,
        data: {
          'tempToken': tempToken,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'password': password,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<AuthResponse> refreshToken({required String refreshToken}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.refreshToken,
        data: {
          'refreshToken': refreshToken,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OTPSendResponse> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {
          'email': email,
        },
      );

      return OTPSendResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> resetPassword({
    required String tempToken,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'tempToken': tempToken,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const NetworkException();
    }

    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;
      final message = data is Map ? data['message'] ?? 'Server error' : 'Server error';

      if (statusCode == 401) {
        return AuthException(message: message);
      } else if (statusCode == 400) {
        return ValidationException(message: message);
      } else if (statusCode == 404) {
        return NotFoundException(message: message);
      } else if (statusCode == 429) {
        return RateLimitException(message: message);
      }
      
      return ServerException(
        message: message,
        statusCode: statusCode,
        data: data,
      );
    }

    return const ServerException(message: 'Unexpected network error');
  }
}
