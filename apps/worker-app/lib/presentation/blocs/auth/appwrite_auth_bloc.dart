import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../core/services/location_service.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/worker_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// AuthBloc for worker authentication.
///
/// Depends on the [AuthRepository]/[WorkerRepository] interfaces so it works
/// against whichever backend is wired up in `injection_container.dart`
/// (REST or Appwrite).
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final WorkerRepository _workerRepository;

  AuthBloc({
    required AuthRepository authRepository,
    required WorkerRepository workerRepository,
  }) : _authRepository = authRepository,
       _workerRepository = workerRepository,
       super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SendOTPRequested>(_onSendOTP);
    on<VerifyOTPRequested>(_onVerifyOTP);
    on<RegisterRequested>(_onRegister);
    on<LoginRequested>(_onLogin);
    on<LogoutRequested>(_onLogout);
    on<RefreshProfile>(_onRefreshProfile);
    on<ForgotPasswordRequested>(_onForgotPassword);
    on<ResetPasswordRequested>(_onResetPassword);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();
      if (isAuthenticated) {
        final worker = await _workerRepository.getProfile();
        emit(Authenticated(worker: worker));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onSendOTP(
    SendOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendOTP(event.phone, event.purpose);
      emit(OTPSent(phone: event.phone, purpose: event.purpose));
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onVerifyOTP(
    VerifyOTPRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.verifyOTP(
        event.phone,
        event.code,
        event.purpose,
      );
      emit(
        OTPVerified(
          isNewUser: response['isNewUser'] ?? true,
          tempToken: response['tempToken'] ?? '',
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
    emit(AuthLoading());
    try {
      await _authRepository.registerWorker(
        tempToken: event.tempToken,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: event.phone,
        password: event.password,
        cnic: event.cnic,
        skills: event.skills,
      );

      final worker = await _workerRepository.getProfile();
      emit(Authenticated(worker: worker));
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await _authRepository.login(event.email, event.password);
      final worker = await _workerRepository.getProfile();
      emit(Authenticated(worker: worker));
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    LocationService().stopAll();
    await _authRepository.logout();
    emit(Unauthenticated());
  }

  /// Re-fetches the worker profile from Appwrite and emits a fresh
  /// [Authenticated] state so all BlocBuilder consumers rebuild with
  /// up-to-date data. Does NOT emit a loading state to avoid flickering.
  Future<void> _onRefreshProfile(
    RefreshProfile event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final worker = await _workerRepository.getProfile();
      emit(Authenticated(worker: worker));
    } catch (_) {
      // Silently ignore — profile will stay at last known state
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.forgotPassword(event.phone);
      emit(OTPSent(phone: event.phone, purpose: 'PASSWORD_RESET'));
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.resetPassword(event.tempToken, event.newPassword);
      emit(const PasswordResetSuccess());
    } catch (e) {
      emit(AuthError(message: ErrorMapper.toUserMessage(e)));
    }
  }
}
