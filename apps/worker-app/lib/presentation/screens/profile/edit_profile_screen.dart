import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/worker_model.dart';
import '../../../domain/repositories/worker_repository.dart';
import '../../../injection_container.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _serviceRadiusController = TextEditingController(text: '10');
  final _bankTitleController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();

  final WorkerRepository _repository = sl<WorkerRepository>();
  bool _isSaving = false;
  bool _isLoading = true;
  WorkerModel? _worker;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Try to get worker from AuthBloc first
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _populateFields(authState.worker);
      setState(() => _isLoading = false);
      return;
    }

    // Otherwise fetch from repository
    try {
      final worker = await _repository.getProfile();
      _populateFields(worker);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load profile: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _populateFields(WorkerModel worker) {
    _worker = worker;
    _firstNameController.text = worker.firstName;
    _lastNameController.text = worker.lastName;
    _emailController.text = worker.user.email ?? '';
    _contactPhoneController.text = worker.contactPhone ?? '';
    _serviceRadiusController.text = worker.serviceRadius.toStringAsFixed(0);
    if (worker.bankDetails != null) {
      _bankTitleController.text = worker.bankDetails!.accountTitle;
      _bankAccountController.text = worker.bankDetails!.accountNumber;
      _bankNameController.text = worker.bankDetails!.bankName;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _contactPhoneController.dispose();
    _serviceRadiusController.dispose();
    _bankTitleController.dispose();
    _bankAccountController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      BankDetails? bankDetails;
      if (_bankTitleController.text.isNotEmpty ||
          _bankAccountController.text.isNotEmpty) {
        bankDetails = BankDetails(
          accountTitle: _bankTitleController.text.trim(),
          accountNumber: _bankAccountController.text.trim(),
          bankName: _bankNameController.text.trim(),
        );
      }

      await _repository.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        contactPhone: _contactPhoneController.text.trim(),
        serviceRadius: double.tryParse(_serviceRadiusController.text),
        bankDetails: bankDetails,
      );

      if (mounted) {
        // Refresh AuthBloc so all screens see updated data
        context.read<AuthBloc>().add(RefreshProfile());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: _worker?.profileImage != null
                                ? NetworkImage(_worker?.profileImage ?? '')
                                : null,
                            child: _worker?.profileImage == null
                                ? Text(
                                    (_worker?.firstName ?? '').isNotEmpty
                                        ? _worker!.firstName[0].toUpperCase()
                                        : 'W',
                                    style: const TextStyle(
                                      fontSize: 36,
                                      color: AppColors.textOnPrimary,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _uploadProfileImage,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v?.isEmpty == true ? 'First name is required' : null,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Last name is required' : null,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email (Optional)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number (Optional)',
                        hintText: 'e.g. 03001234567',
                        prefixIcon: Icon(Icons.call_outlined),
                        helperText: 'Used by customers to call you',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.isEmpty) return null;
                        final pattern = RegExp(r'^(\+92|0)?3[0-9]{9}$');
                        return pattern.hasMatch(v)
                            ? null
                            : 'Enter a valid Pakistani mobile number';
                      },
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    const Text(
                      'Service Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _serviceRadiusController,
                      decoration: const InputDecoration(
                        labelText: 'Service Radius (km)',
                        prefixIcon: Icon(Icons.my_location),
                        helperText:
                            'Maximum distance you are willing to travel',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    const Text(
                      'Bank Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _bankTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Account Title',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _bankAccountController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (image != null) {
      try {
        await _repository.uploadProfileImage(image.path);
        // Refresh worker profile to get the new image URL
        final updatedWorker = await _repository.getProfile();
        if (mounted) {
          setState(() {
            _worker = updatedWorker;
          });
          // Refresh AuthBloc so profile screen shows new image
          context.read<AuthBloc>().add(RefreshProfile());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Upload failed: ${e.toString().replaceAll("Exception: ", "")}',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
