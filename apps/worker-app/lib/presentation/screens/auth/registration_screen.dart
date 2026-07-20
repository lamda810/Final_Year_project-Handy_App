import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/phone_number_service.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/worker_model.dart';

class RegistrationScreen extends StatefulWidget {
  final String tempToken;
  final String phone;

  const RegistrationScreen({
    super.key,
    required this.tempToken,
    required this.phone,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;
  bool _detectingPhone = false;

  // Skills selection
  final List<String> _availableSkills = [
    'PLUMBING',
    'ELECTRICAL',
    'CLEANING',
    'AC_REPAIR',
    'CARPENTER',
    'PAINTING',
    'MECHANIC',
    'GENERAL_HANDYMAN',
  ];
  final Set<String> _selectedSkills = {};

  @override
  void initState() {
    super.initState();
    // Pre-fill with the number verified via OTP (strip +92, since the field
    // shows a fixed +92 prefix and expects the local 10-digit number).
    var verifiedPhone = widget.phone;
    if (verifiedPhone.startsWith('+92')) {
      verifiedPhone = verifiedPhone.substring(3);
    } else if (verifiedPhone.startsWith('0')) {
      verifiedPhone = verifiedPhone.substring(1);
    }
    _phoneController.text = verifiedPhone;
    if (verifiedPhone.isEmpty) {
      _autoDetectPhoneNumber();
    }
  }

  /// Attempt to auto-detect SIM phone number and pre-fill the field
  Future<void> _autoDetectPhoneNumber() async {
    if (_phoneController.text.isNotEmpty) return; // Already filled

    setState(() => _detectingPhone = true);
    try {
      final phone = await PhoneNumberService.getPrimaryPhoneNumber();
      if (phone != null && phone.isNotEmpty && mounted) {
        // Convert +923001234567 → 3001234567 (without leading 0, since UI shows +92 prefix)
        String localPhone = phone;
        if (localPhone.startsWith('+92')) {
          localPhone = localPhone.substring(3);
        } else if (localPhone.startsWith('92')) {
          localPhone = localPhone.substring(2);
        } else if (localPhone.startsWith('0')) {
          localPhone = localPhone.substring(1);
        }
        // Only set if still empty (user hasn't typed)
        if (_phoneController.text.isEmpty) {
          _phoneController.text = localPhone;
          debugPrint(
            '[WorkerRegistration] Auto-detected SIM phone: $localPhone',
          );
        }
      }
    } catch (e) {
      debugPrint('[WorkerRegistration] SIM phone detection failed: $e');
    } finally {
      if (mounted) setState(() => _detectingPhone = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one skill'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms & Conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final skills = _selectedSkills.map((skill) {
      return SkillModel(
        category: skill,
        experience: 1, // Default experience
        hourlyRate: 500, // Default hourly rate
        isVerified: false,
      );
    }).toList();

    context.read<AuthBloc>().add(
      RegisterRequested(
        tempToken: widget.tempToken,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? '+92${_phoneController.text.replaceAll(RegExp(r'[\s\-]'), '')}'
            : null,
        password: _passwordController.text,
        cnic: _cnicController.text.replaceAll('-', ''),
        skills: skills,
      ),
    );
  }

  String _getSkillDisplayName(String skill) {
    switch (skill) {
      case 'PLUMBING':
        return 'Plumbing';
      case 'ELECTRICAL':
        return 'Electrical';
      case 'CLEANING':
        return 'Cleaning';
      case 'AC_REPAIR':
        return 'AC Repair';
      case 'CARPENTER':
        return 'Carpenter';
      case 'PAINTING':
        return 'Painting';
      case 'MECHANIC':
        return 'Mechanic';
      case 'GENERAL_HANDYMAN':
        return 'General Handyman';
      default:
        return skill;
    }
  }

  IconData _getSkillIcon(String skill) {
    switch (skill) {
      case 'PLUMBING':
        return Icons.plumbing;
      case 'ELECTRICAL':
        return Icons.electrical_services;
      case 'CLEANING':
        return Icons.cleaning_services;
      case 'AC_REPAIR':
        return Icons.ac_unit;
      case 'CARPENTER':
        return Icons.carpenter;
      case 'PAINTING':
        return Icons.format_paint;
      case 'MECHANIC':
        return Icons.build;
      case 'GENERAL_HANDYMAN':
        return Icons.handyman;
      default:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() {
          _isLoading = state is AuthLoading;
        });

        if (state is Authenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            }
          });
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Create Account')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Info Section
                    Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Name Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'First Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.givenName],
                            validator: (v) =>
                                Validators.validateRequired(v, 'First name'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'Last Name',
                            ),
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.familyName],
                            validator: (v) =>
                                Validators.validateRequired(v, 'Last name'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Verified phone number (from OTP step)
                    TextFormField(
                      controller: _phoneController,
                      readOnly: true,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: InputDecoration(
                        labelText: 'Phone Number (Verified)',
                        hintText: '3XX XXXXXXX',
                        prefixIcon: Container(
                          width: 80,
                          alignment: Alignment.center,
                          child: const Text(
                            '+92',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        suffixIcon: _detectingPhone
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.sim_card_outlined),
                                tooltip: 'Detect from SIM',
                                onPressed: _autoDetectPhoneNumber,
                              ),
                      ),
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // CNIC
                    TextFormField(
                      controller: _cnicController,
                      decoration: const InputDecoration(
                        labelText: 'CNIC Number',
                        hintText: 'XXXXX-XXXXXXX-X',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.validateCNIC,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Skills Section
                    Text(
                      'Select Your Skills',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Choose the services you can provide',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _availableSkills.map((skill) {
                        final isSelected = _selectedSkills.contains(skill);
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getSkillIcon(skill),
                                size: 18,
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getSkillDisplayName(skill),
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSkills.add(skill);
                              } else {
                                _selectedSkills.remove(skill);
                              }
                            });
                          },
                          selectedColor: AppColors.primaryLight.withValues(
                            alpha: 0.4,
                          ),
                          checkmarkColor: AppColors.primaryDark,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Password Section
                    Text(
                      'Create Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (v) => Validators.validateConfirmPassword(
                        v,
                        _passwordController.text,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Terms Checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms of Service',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(
                                        Uri.parse('https://handygo.app/terms'),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launchUrl(
                                        Uri.parse(
                                          'https://handygo.app/privacy',
                                        ),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Register Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
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
                          : const Text('Create Account'),
                    ),

                    const SizedBox(height: AppSpacing.md),
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
