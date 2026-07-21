import '../../models/auth_response_model.dart';

/// Remote data source for authentication operations
abstract class AuthRemoteDataSource {
  Future<OTPSendResponse> sendOTP({
    required String phone,
    required String purpose,
  });

  Future<OTPVerificationResult> verifyOTP({
    required String phone,
    required String code,
    required String purpose,
  });

  Future<AuthResponse> register({
    required String tempToken,
    required String firstName,
    required String lastName,
    String? phone,
    required String password,
  });

  Future<AuthResponse> login({required String email, required String password});

  Future<AuthResponse> refreshToken({required String refreshToken});

  /// Request password reset OTP
  Future<OTPSendResponse> forgotPassword({required String phone});

  /// Reset password with verified token
  Future<void> resetPassword({
    required String tempToken,
    required String newPassword,
  });

  /// End the current authenticated session on the backend.
  Future<void> logout();
}
