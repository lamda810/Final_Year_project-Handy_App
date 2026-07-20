import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../core/constants/api_endpoints.dart';
import '../../data/models/worker_model.dart';

/// REST implementation of AuthRepository for the Worker app
class RestAuthRepository implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  RestAuthRepository({
    required Dio dio,
    required FlutterSecureStorage secureStorage,
  }) : _dio = dio,
       _secureStorage = secureStorage;

  @override
  Future<Map<String, dynamic>> sendOTP(String phone, String purpose) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.sendOtp,
        data: {
          'phone': phone,
          'purpose': purpose,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOTP(
    String phone,
    String code,
    String purpose,
  ) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {
          'phone': phone,
          'code': code,
          'purpose': purpose,
        },
      );
      return response.data['data'] ?? response.data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> registerWorker({
    required String tempToken,
    required String firstName,
    required String lastName,
    String? phone,
    required String password,
    required String cnic,
    required List<SkillModel> skills,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.registerWorker,
        data: {
          'tempToken': tempToken,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'password': password,
          'cnic': cnic,
          'skills': skills.map((s) => s.toJson()).toList(),
        },
      );

      final data = response.data['data'] ?? response.data;
      if (data['accessToken'] != null) {
        await _saveTokens(data['accessToken'], data['refreshToken']);
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      final data = response.data['data'] ?? response.data;
      if (data['accessToken'] != null) {
        await _saveTokens(data['accessToken'], data['refreshToken']);
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> forgotPassword(String phone) async {
    await _dio.post(ApiEndpoints.forgotPassword, data: {'phone': phone});
  }

  @override
  Future<void> resetPassword(String tempToken, String newPassword) async {
    await _dio.post(
      ApiEndpoints.resetPassword,
      data: {
        'tempToken': tempToken,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await _secureStorage.write(key: 'access_token', value: access);
    await _secureStorage.write(key: 'refresh_token', value: refresh);
  }
}
