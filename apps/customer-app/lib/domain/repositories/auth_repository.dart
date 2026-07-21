import '../../data/models/user_model.dart';
import '../../data/models/auth_response_model.dart';

/// Abstract auth repository interface
abstract class AuthRepository {
  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Check if this is first time user (for onboarding)
  Future<bool> isFirstTimeUser();

  /// Mark onboarding as completed
  Future<void> completeOnboarding();

  /// Get current logged in user
  Future<UserModel?> getCurrentUser();

  /// Send OTP to a phone number
  Future<OTPSendResponse> sendOTP({
    required String phone,
    required String purpose,
  });

  /// Verify OTP code
  Future<OTPVerificationResult> verifyOTP({
    required String phone,
    required String code,
    required String purpose,
  });

  /// Register new customer
  Future<UserModel> register({
    required String tempToken,
    required String firstName,
    required String lastName,
    String? phone,
    required String password,
  });

  /// Login with email and password
  Future<UserModel> login({required String email, required String password});

  /// Refresh access token
  Future<void> refreshToken();

  /// Request password reset OTP (forgot password)
  Future<void> forgotPassword({required String phone});

  /// Reset password
  Future<void> resetPassword({
    required String tempToken,
    required String newPassword,
  });

  /// Logout
  Future<void> logout();

  /// Get stored access token
  Future<String?> getAccessToken();

  /// Get stored refresh token
  Future<String?> getRefreshToken();
}
