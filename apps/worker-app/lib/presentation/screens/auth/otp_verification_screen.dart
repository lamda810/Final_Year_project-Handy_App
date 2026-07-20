import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final String purpose;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.purpose,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final StreamController<ErrorAnimationType> _errorController =
      StreamController<ErrorAnimationType>();

  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _errorController.close();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  void _resendOTP() {
    if (_canResend) {
      context.read<AuthBloc>().add(
        SendOTPRequested(phone: widget.phone, purpose: widget.purpose),
      );
      _startTimer();
    }
  }

  void _verifyOTP(String otp) {
    if (otp.length == 6) {
      context.read<AuthBloc>().add(
        VerifyOTPRequested(
          phone: widget.phone,
          code: otp,
          purpose: widget.purpose,
        ),
      );
    }
  }

  String get _maskedPhone {
    if (widget.phone.length > 4) {
      final visible = widget.phone.substring(widget.phone.length - 4);
      final masked = '*' * (widget.phone.length - 4);
      return '$masked$visible';
    }
    return widget.phone;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _isLoading = state is AuthLoading;
        });

        if (state is OTPVerified) {
          if (widget.purpose == 'PASSWORD_RESET') {
            // Navigate to reset password screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.resetPassword,
                  arguments: {
                    'tempToken': state.tempToken,
                    'phone': state.phone,
                  },
                );
              }
            });
          } else if (state.isNewUser) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.registration,
                  arguments: {
                    'tempToken': state.tempToken,
                    'phone': state.phone,
                  },
                );
              }
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            });
          }
        } else if (state is AuthError) {
          _otpController.clear();
          _errorController.add(ErrorAnimationType.shake);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Verification')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sms_outlined,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                Text(
                  'Enter the 6-digit code sent to\n$_maskedPhone',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xl),

                // OTP Input (pin_code_fields)
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  errorAnimationController: _errorController,
                  animationType: AnimationType.fade,
                  keyboardType: TextInputType.number,
                  autoFocus: true,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                    fieldHeight: 56,
                    fieldWidth: 48,
                    activeFillColor: Theme.of(context).colorScheme.surface,
                    inactiveFillColor: Theme.of(context).colorScheme.surface,
                    selectedFillColor: Theme.of(context).colorScheme.surface,
                    activeColor: AppColors.primary,
                    inactiveColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.3),
                    selectedColor: AppColors.primary,
                  ),
                  enableActiveFill: true,
                  onCompleted: _verifyOTP,
                  onChanged: (_) {},
                ),

                const SizedBox(height: AppSpacing.xl),

                // Resend Timer
                if (!_canResend)
                  Text(
                    'Resend code in ${_remainingSeconds}s',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _resendOTP,
                    child: const Text('Resend Code'),
                  ),

                const Spacer(),

                // Verify Button
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _verifyOTP(_otpController.text),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textOnPrimary,
                            ),
                          ),
                        )
                      : const Text('Verify'),
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
