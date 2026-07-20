import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/user_model.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/booking/booking_event.dart';
import '../../blocs/booking/booking_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_event.dart';
import '../../blocs/user/user_state.dart';

/// Profile screen showing user profile and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user profile when screen loads
    context.read<UserBloc>().add(const LoadProfileRequested());
    // Load bookings to compute stats
    context.read<BookingBloc>().add(const LoadBookingsRequested(limit: 100));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              _showSettingsBottomSheet(context);
            },
          ),
        ],
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is UserProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is AccountDeleted) {
            // Account deleted successfully — schedule navigation after frame
            // to avoid InheritedWidget dependency assertion
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted successfully'),
                backgroundColor: AppColors.success,
              ),
            );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<AuthBloc>().add(const LogoutRequested());
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            });
          }
        },
        builder: (context, state) {
          if (state is UserLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UserProfileLoaded) {
            return _buildProfileContent(
              context,
              state.profile,
              state.addresses,
            );
          }

          // Initial or error state - show retry option
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 64,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Unable to load profile',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ElevatedButton(
                  onPressed: () {
                    context.read<UserBloc>().add(const LoadProfileRequested());
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Escape hatch when the profile can't load (e.g. an expired
                // or invalid session): allow logging out to reach the login
                // screen again.
                TextButton.icon(
                  onPressed: () => _showLogoutConfirmation(context),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    CustomerModel profile,
    List<AddressModel> addresses,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<UserBloc>().add(const LoadProfileRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md + 16,
        ),
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(context, profile),

            const SizedBox(height: AppSpacing.lg),

            // Quick stats
            _buildQuickStats(profile, addresses),

            const SizedBox(height: AppSpacing.lg),

            // Menu sections
            _buildMenuSection('Account', [
              _MenuItem(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () => _showEditProfileDialog(context, profile),
              ),
              _MenuItem(
                icon: Icons.location_on_outlined,
                title: 'Saved Addresses',
                trailing: '${addresses.length}',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.savedAddresses),
              ),
              _MenuItem(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.paymentMethods),
              ),
              _MenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: 'My Wallet',
                trailing: 'Rs. 0',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.wallet),
              ),
            ]),

            const SizedBox(height: AppSpacing.md),

            _buildMenuSection('Preferences', [
              _MenuItem(
                icon: Icons.language_outlined,
                title: 'Language',
                trailing: profile.preferredLanguage == 'ur'
                    ? 'اردو'
                    : 'English',
                onTap: () => _showLanguageSelector(context),
              ),
              _MenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(AppRoutes.notificationSettings),
              ),
              _MenuItem(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                isSwitch: true,
                switchValue:
                    HandyGoApp.themeModeNotifier.value == ThemeMode.dark,
                onTap: () => _toggleDarkMode(),
              ),
            ]),

            const SizedBox(height: AppSpacing.md),

            _buildMenuSection('Support', [
              _MenuItem(
                icon: Icons.help_outline,
                title: 'Help Center',
                onTap: () => _showHelpCenter(context),
              ),
              _MenuItem(
                icon: Icons.chat_bubble_outline,
                title: 'Contact Us',
                onTap: () => _showContactUs(context),
              ),
              _MenuItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.termsConditions),
              ),
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.privacyPolicy),
              ),
            ]),

            const SizedBox(height: AppSpacing.lg),

            // Logout button
            _buildLogoutButton(context),

            const SizedBox(height: AppSpacing.md),

            // App version
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, CustomerModel profile) {
    final initials = _getInitials(profile.firstName, profile.lastName);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile image
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: profile.profileImage != null
                    ? NetworkImage(profile.profileImage!)
                    : null,
                child: profile.profileImage == null
                    ? Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickAndUploadProfileImage(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customer ID: ${profile.id.length > 6 ? profile.id.substring(profile.id.length - 6) : profile.id}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Verified Account',
                      style: TextStyle(fontSize: 12, color: AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
            onPressed: () => _showEditProfileDialog(context, profile),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(CustomerModel profile, List<AddressModel> addresses) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        double averageRating = 0;
        int ratedCount = 0;

        if (state is BookingsLoaded) {
          final ratings = state.bookings
              .where((b) => b.rating != null)
              .map((b) => b.rating!.score);
          for (final rating in ratings) {
            averageRating += rating;
            ratedCount += 1;
          }
        }

        final avgDisplay = ratedCount > 0
            ? (averageRating / ratedCount).toStringAsFixed(1)
            : '0.0';

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.calendar_today,
                value: '${profile.totalBookings}',
                label: 'Bookings',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                value: avgDisplay,
                label: 'Avg Rating',
                color: AppColors.ratingStar,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildStatCard(
                icon: Icons.favorite,
                value: '${addresses.length}',
                label: 'Favorites',
                color: AppColors.error,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  _buildMenuItem(item),
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(_MenuItem item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            item.icon,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            size: 20,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(fontSize: 15, color: colorScheme.onSurface),
        ),
        trailing: item.isSwitch
            ? Switch(
                value: item.switchValue ?? false,
                onChanged: (_) => item.onTap(),
                activeThumbColor: AppColors.primary,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.trailing != null)
                    Text(
                      item.trailing ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  const SizedBox(width: 4),
                  if (!item.isSwitch)
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                ],
              ),
        onTap: item.isSwitch ? null : item.onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutConfirmation(context),
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text('Logout', style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
      ),
    );
  }

  // Helper methods
  String _getInitials(String firstName, String lastName) {
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();
    return initials.isEmpty ? 'U' : initials;
  }

  Future<void> _pickAndUploadProfileImage(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    // TODO: Upload the picked image once the backend exposes a storage
    // endpoint, then send its URL via UpdateProfileRequested(profileImage: …).
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Profile photo upload is not available yet'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleDarkMode() async {
    final currentMode = HandyGoApp.themeModeNotifier.value;
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    HandyGoApp.themeModeNotifier.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );
    // The ValueListenableBuilder in app.dart rebuilds the MaterialApp,
    // which naturally rebuilds this screen — no setState needed.
  }

  void _showEditProfileDialog(BuildContext context, CustomerModel profile) {
    final firstNameController = TextEditingController(text: profile.firstName);
    final lastNameController = TextEditingController(text: profile.lastName);
    final contactPhoneController = TextEditingController(
      text: profile.contactPhone ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                hintText: 'e.g. 03001234567',
                helperText: 'Used by workers to call you. Optional.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final firstName = firstNameController.text.trim();
              final lastName = lastNameController.text.trim();
              final contactPhone = contactPhoneController.text.trim();
              final phonePattern = RegExp(r'^(\+92|0)?3[0-9]{9}$');

              if (firstName.isEmpty || lastName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('First name and last name are required'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              if (contactPhone.isNotEmpty && !phonePattern.hasMatch(contactPhone)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter a valid Pakistani mobile number (e.g. 03001234567)',
                    ),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              context.read<UserBloc>().add(
                UpdateProfileRequested(
                  firstName: firstName,
                  lastName: lastName,
                  contactPhone: contactPhone,
                ),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    // Import the app.dart's localeNotifier
    final currentLocale = _getCurrentLocale();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Language / زبان منتخب کریں',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
            title: const Text('English'),
            subtitle: const Text('Default language'),
            trailing: currentLocale == 'en'
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              _changeLanguage('en');
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language changed to English'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          ListTile(
            leading: const Text('🇵🇰', style: TextStyle(fontSize: 24)),
            title: const Text('اردو'),
            subtitle: const Text('Urdu'),
            trailing: currentLocale == 'ur'
                ? const Icon(Icons.check_circle, color: AppColors.primary)
                : null,
            onTap: () {
              _changeLanguage('ur');
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('زبان اردو میں تبدیل ہو گئی'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getCurrentLocale() {
    // Access the locale from HandyGoApp
    try {
      return Localizations.localeOf(context).languageCode;
    } catch (_) {
      return 'en';
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    // Update the app's locale
    // This requires importing the app.dart and using the localeNotifier
    // For now, we'll use the HandyGoApp.localeNotifier directly
    final newLocale = Locale(languageCode);

    // Update global locale notifier
    // Import ../../app.dart at the top of this file
    _updateAppLocale(newLocale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_language', languageCode);

    // Also update user preference on backend
    if (!mounted) return;
    context.read<UserBloc>().add(
      UpdateProfileRequested(preferredLanguage: languageCode),
    );

    // Trigger rebuild
    setState(() {});
  }

  void _updateAppLocale(Locale newLocale) {
    // Update HandyGoApp's static localeNotifier
    HandyGoApp.localeNotifier.value = newLocale;
  }

  void _showContactUs(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Contact Us',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: AppColors.primary),
            title: const Text('Email'),
            subtitle: const Text('f2023266257@umt.edu.pk'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final Uri emailUri = Uri(
                scheme: 'mailto',
                path: 'f2023266257@umt.edu.pk',
                queryParameters: {'subject': 'HandyGo Support Request'},
              );
              try {
                await launchUrl(emailUri, mode: LaunchMode.externalApplication);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open email app')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
            title: const Text('Phone'),
            subtitle: const Text('+92 302 2389814'),
            onTap: () async {
              Navigator.pop(sheetContext);
              final Uri phoneUri = Uri(scheme: 'tel', path: '+923022389814');
              try {
                await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open phone app')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_outlined, color: AppColors.success),
            title: const Text('WhatsApp'),
            subtitle: const Text('+92 302 2389814'),
            onTap: () async {
              Navigator.pop(sheetContext);
              // Try WhatsApp first, then WhatsApp Business
              final Uri waUri = Uri.parse(
                'whatsapp://send?phone=923022389814&text=Hello, I need help with HandyGo app',
              );
              final Uri waBusinessUri = Uri.parse(
                'https://wa.me/923022389814?text=Hello, I need help with HandyGo app',
              );
              try {
                final launched = await launchUrl(
                  waUri,
                  mode: LaunchMode.externalApplication,
                );
                if (!launched) {
                  await launchUrl(
                    waBusinessUri,
                    mode: LaunchMode.externalApplication,
                  );
                }
              } catch (_) {
                try {
                  await launchUrl(
                    waBusinessUri,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open WhatsApp')),
                    );
                  }
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notification Settings'),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(context).pushNamed(AppRoutes.notificationSettings);
            },
          ),
          ListTile(
            leading: const Icon(Icons.security_outlined),
            title: const Text('Privacy & Security'),
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.of(context).pushNamed(AppRoutes.privacyPolicy);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              _showDeleteAccountConfirmation(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
          'This action is irreversible and all your data will be permanently deleted, including:\n\n'
          '• Your profile information\n'
          '• Booking history\n'
          '• Saved addresses\n'
          '• Wallet balance\n\n'
          'Please enter "DELETE" to confirm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showDeleteConfirmationInput(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationInput(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type "DELETE" to confirm account deletion:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().toUpperCase() == 'DELETE') {
                Navigator.pop(dialogContext);
                // Call delete account API
                context.read<UserBloc>().add(const DeleteAccountRequested());
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type DELETE to confirm'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Help Center',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFAQItem(
                    'How do I book a service?',
                    'Select a service category from the home screen, describe your problem, choose a location and time slot, then select a worker from the list.',
                  ),
                  _buildFAQItem(
                    'How can I cancel a booking?',
                    'Go to your bookings, select the booking you want to cancel, and tap the Cancel button. Note that cancellation charges may apply.',
                  ),
                  _buildFAQItem(
                    'What payment methods are accepted?',
                    'We accept Cash on Delivery and HandyGo Wallet. Card and mobile wallet payments will be available soon.',
                  ),
                  _buildFAQItem(
                    'How do I track my worker?',
                    'Once a worker accepts your booking, you can track their real-time location on the booking tracking screen.',
                  ),
                  _buildFAQItem(
                    'What is the SOS feature?',
                    'The SOS button allows you to report emergencies during a service. Our team will respond immediately to ensure your safety.',
                  ),
                  _buildFAQItem(
                    'How do I leave a review?',
                    'After your service is completed, you\'ll be prompted to rate and review the worker. You can also rate later from your booking history.',
                  ),
                  _buildFAQItem(
                    'How do I update my profile?',
                    'Go to Profile > Edit Profile to update your name and other details.',
                  ),
                  _buildFAQItem(
                    'How do I add/manage addresses?',
                    'Go to Profile > Saved Addresses to add, edit, or delete your addresses.',
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Still need help?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showContactUs(context);
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Contact Support'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Clear user data from UserBloc
              context.read<UserBloc>().add(const ClearUserDataRequested());
              // Logout through AuthBloc
              context.read<AuthBloc>().add(const LogoutRequested());
              // Navigate to login
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool isSwitch;
  final bool? switchValue;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.isSwitch = false,
    this.switchValue,
    required this.onTap,
  });
}
