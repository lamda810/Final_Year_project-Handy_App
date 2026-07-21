import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

/// Login screen for existing users
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  int _wrongPasswordAttempts = 0;
  static const int _maxWrongAttempts = 3;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    // Accounts are now phone-verified at signup (no email collected), but
    // this field accepts either — the datasource routes it to the right
    // backend field based on whether it looks like an email.
    final identifier = _emailController.text.trim();
    final normalized = identifier.contains('@')
        ? identifier.toLowerCase()
        : identifier;

    context.read<AuthBloc>().add(
      LoginRequested(email: normalized, password: _passwordController.text),
    );
  }

  void _forgotPassword() {
    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is Authenticated) {
      // Reset attempts on successful login
      _wrongPasswordAttempts = 0;

      final preferredLanguage = state.user.customer?.preferredLanguage ?? 'en';
      HandyGoApp.localeNotifier.value = Locale(preferredLanguage);

      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('preferred_language', preferredLanguage);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
        }
      });
    } else if (state is AuthError) {
      String errorMessage = state.message;

      // Check if it's a password error and show appropriate message
      if (errorMessage.toLowerCase().contains('invalid') ||
          errorMessage.toLowerCase().contains('password') ||
          errorMessage.toLowerCase().contains('unauthorized')) {
        _wrongPasswordAttempts++;

        if (_wrongPasswordAttempts >= _maxWrongAttempts) {
          // Show dialog and redirect to forgot password
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Too Many Attempts'),
              content: const Text(
                'You have entered the wrong password too many times. '
                'Please reset your password to continue.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _wrongPasswordAttempts = 0;
                    Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                  },
                  child: const Text('Reset Password'),
                ),
              ],
            ),
          );
          return;
        }

        final remainingAttempts = _maxWrongAttempts - _wrongPasswordAttempts;
        errorMessage =
            'Invalid password. $remainingAttempts attempt${remainingAttempts != 1 ? 's' : ''} remaining.';
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthState,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Header
                    Text(
                      AppStrings.welcomeBack,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      'Login to your account',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Phone or email input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(
                        labelText: 'Phone or Email',
                        hintText: '+92 3XX XXXXXXX or you@example.com',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          Validators.required(value, fieldName: 'Phone or email'),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Password input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: AppStrings.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) =>
                          Validators.required(value, fieldName: 'Password'),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Login button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(AppStrings.login),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.dontHaveAccount,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.emailInput);
                          },
                          child: const Text(
                            AppStrings.signUp,
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
