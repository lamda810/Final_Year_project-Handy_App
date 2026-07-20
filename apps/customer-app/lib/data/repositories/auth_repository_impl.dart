import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import '../../data/models/auth_response_model.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import 'dart:convert';

/// Auth repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SharedPreferences _sharedPreferences;
  final FlutterSecureStorage _secureStorage;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'current_user';
  static const String _onboardingKey = 'onboarding_completed';

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SharedPreferences sharedPreferences,
    required FlutterSecureStorage secureStorage,
  }) : _remoteDataSource = remoteDataSource,
       _sharedPreferences = sharedPreferences,
       _secureStorage = secureStorage;

  @override
  Future<bool> isLoggedIn() async {
    // First check local token cache
    final accessToken = await getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      return true;
    }
    return false;
  }

  @override
  Future<bool> isFirstTimeUser() async {
    return !(_sharedPreferences.getBool(_onboardingKey) ?? false);
  }

  @override
  Future<void> completeOnboarding() async {
    await _sharedPreferences.setBool(_onboardingKey, true);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final userJson = _sharedPreferences.getString(_userKey);
    if (userJson != null) {
      try {
        return UserModel.fromJson(json.decode(userJson));
      } catch (e) {
        // Fall through to fetch from remote
      }
    }

    return null;
  }

  @override
  Future<OTPSendResponse> sendOTP({
    required String email,
    required String purpose,
  }) async {
    return await _remoteDataSource.sendOTP(email: email, purpose: purpose);
  }

  @override
  Future<OTPVerificationResult> verifyOTP({
    required String email,
    required String code,
    required String purpose,
  }) async {
    return await _remoteDataSource.verifyOTP(
      email: email,
      code: code,
      purpose: purpose,
    );
  }

  @override
  Future<UserModel> register({
    required String tempToken,
    required String firstName,
    required String lastName,
    String? phone,
    required String password,
  }) async {
    final response = await _remoteDataSource.register(
      tempToken: tempToken,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      password: password,
    );

    await _saveAuthResponse(response);
    return response.user;
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      email: email,
      password: password,
    );

    await _saveAuthResponse(response);
    return response.user;
  }

  @override
  Future<void> refreshToken() async {
    final currentRefreshToken = await getRefreshToken();
    if (currentRefreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await _remoteDataSource.refreshToken(
      refreshToken: currentRefreshToken,
    );

    await _secureStorage.write(
      key: _accessTokenKey,
      value: response.accessToken,
    );
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: response.refreshToken,
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<void> resetPassword({
    required String tempToken,
    required String newPassword,
  }) async {
    await _remoteDataSource.resetPassword(
      tempToken: tempToken,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _remoteDataSource.logout();
    } catch (_) {
      // Best effort — clear local state regardless
    }
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _sharedPreferences.remove(_userKey);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> _saveAuthResponse(AuthResponse response) async {
    await _secureStorage.write(
      key: _accessTokenKey,
      value: response.accessToken,
    );
    await _secureStorage.write(
      key: _refreshTokenKey,
      value: response.refreshToken,
    );
    await _sharedPreferences.setString(
      _userKey,
      json.encode(response.user.toJson()),
    );
  }
}
