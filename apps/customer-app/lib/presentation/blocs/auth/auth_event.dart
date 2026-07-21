import 'package:equatable/equatable.dart';

/// Base auth event
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check authentication status on app startup
class CheckAuthStatusRequested extends AuthEvent {
  const CheckAuthStatusRequested();
}

/// Event to send OTP to a phone number
class SendOTPRequested extends AuthEvent {
  final String phone;
  final String purpose; // REGISTRATION, LOGIN, PASSWORD_RESET

  const SendOTPRequested({required this.phone, required this.purpose});

  @override
  List<Object?> get props => [phone, purpose];
}

/// Event to verify OTP code
class VerifyOTPRequested extends AuthEvent {
  final String phone;
  final String code;
  final String purpose;

  const VerifyOTPRequested({
    required this.phone,
    required this.code,
    required this.purpose,
  });

  @override
  List<Object?> get props => [phone, code, purpose];
}

/// Event to register a new customer
class RegisterRequested extends AuthEvent {
  final String tempToken;
  final String firstName;
  final String lastName;
  final String? phone;
  final String password;

  const RegisterRequested({
    required this.tempToken,
    required this.firstName,
    required this.lastName,
    this.phone,
    required this.password,
  });

  @override
  List<Object?> get props => [tempToken, firstName, lastName, phone, password];
}

/// Event to login with email and password
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Event to logout
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event to request forgot password OTP
class ForgotPasswordRequested extends AuthEvent {
  final String phone;

  const ForgotPasswordRequested({required this.phone});

  @override
  List<Object?> get props => [phone];
}

/// Event to reset password
class ResetPasswordRequested extends AuthEvent {
  final String tempToken;
  final String newPassword;

  const ResetPasswordRequested({
    required this.tempToken,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [tempToken, newPassword];
}

/// Event to refresh access token
class RefreshTokenRequested extends AuthEvent {
  const RefreshTokenRequested();
}
