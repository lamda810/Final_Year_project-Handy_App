import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<CheckAuthStatusRequested>(_onCheckAuthStatus);
    on<SendOTPRequested>(_onSendOTP);
    on<VerifyOTPRequested>(_onVerifyOTP);
    on<RegisterRequested>(_onRegister);
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
    on<RefreshTokenRequested>(_onRefreshToken);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking authentication...'));

    try {
      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _authRepository.getCurrentUser();
        if (user != null) {
          emit(Authenticated(user: user));
        } else {
          final isFirstTime = await _authRepository.isFirstTimeUser();
          emit(Unauthenticated(isFirstTime: isFirstTime));
        }
      } else {
        final isFirstTime = await _authRepository.isFirstTimeUser();
        emit(Unauthenticated(isFirstTime: isFirstTime));
      }
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onSendOTP(
    SendOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending OTP...'));

    try {
      await _authRepository.sendOTP(phone: event.phone, purpose: event.purpose);
      emit(OTPSent(phone: event.phone, purpose: event.purpose));
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onVerifyOTP(
    VerifyOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Verifying OTP...'));

    try {
      final result = await _authRepository.verifyOTP(
        phone: event.phone,
        code: event.code,
        purpose: event.purpose,
      );
      emit(
        OTPVerified(
          isNewUser: result.isNewUser,
          tempToken: result.tempToken,
          phone: event.phone,
        ),
      );
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Creating account...'));

    try {
      final user = await _authRepository.register(
        tempToken: event.tempToken,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        password: event.password,
      );
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Logging in...'));

    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(Authenticated(user: user));
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(message: 'Logging out...'));

    try {
      await _authRepository.logout();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Sending password reset OTP...'));

    try {
      await _authRepository.forgotPassword(phone: event.phone);
      emit(OTPSent(phone: event.phone, purpose: 'PASSWORD_RESET'));
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Resetting password...'));

    try {
      await _authRepository.resetPassword(
        tempToken: event.tempToken,
        newPassword: event.newPassword,
      );
      emit(const PasswordResetSuccess());
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onRefreshToken(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.refreshToken();
    } catch (e) {
      emit(const Unauthenticated());
    }
  }
}
