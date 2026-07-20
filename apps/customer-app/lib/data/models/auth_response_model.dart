import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// OTP verification result
class OTPVerificationResult extends Equatable {
  final bool isNewUser;
  final String tempToken;

  const OTPVerificationResult({
    required this.isNewUser,
    required this.tempToken,
  });

  factory OTPVerificationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return OTPVerificationResult(
      isNewUser: data['isNewUser'] ?? true,
      tempToken: data['tempToken'] ?? '',
    );
  }

  @override
  List<Object?> get props => [isNewUser, tempToken];
}

/// Auth response containing user and tokens
class AuthResponse extends Equatable {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return AuthResponse(
      user: UserModel.fromJson(data['user']),
      accessToken: data['accessToken'] ?? '',
      refreshToken: data['refreshToken'] ?? '',
    );
  }

  @override
  List<Object?> get props => [user, accessToken, refreshToken];
}

/// OTP send response
class OTPSendResponse extends Equatable {
  final bool success;
  final String message;
  final String? otpId;

  const OTPSendResponse({
    required this.success,
    required this.message,
    this.otpId,
  });

  factory OTPSendResponse.fromJson(Map<String, dynamic> json) {
    return OTPSendResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      otpId: json['data']?['otpId'],
    );
  }

  @override
  List<Object?> get props => [success, message, otpId];
}
