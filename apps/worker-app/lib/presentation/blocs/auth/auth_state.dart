import 'package:equatable/equatable.dart';
import '../../../data/models/worker_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class OTPSent extends AuthState {
  final String phone;
  final String purpose;

  const OTPSent({required this.phone, required this.purpose});

  @override
  List<Object?> get props => [phone, purpose];
}

class OTPVerified extends AuthState {
  final bool isNewUser;
  final String tempToken;
  final String phone;

  const OTPVerified({
    required this.isNewUser,
    required this.tempToken,
    required this.phone,
  });

  @override
  List<Object?> get props => [isNewUser, tempToken, phone];
}

class Authenticated extends AuthState {
  final WorkerModel worker;

  const Authenticated({required this.worker});

  @override
  List<Object?> get props => [worker];
}

class Unauthenticated extends AuthState {}

class PasswordResetSuccess extends AuthState {
  const PasswordResetSuccess();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}
