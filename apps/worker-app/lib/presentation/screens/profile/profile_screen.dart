import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../data/models/worker_model.dart';
import '../../../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh profile data from server to ensure stats are up-to-date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(RefreshProfile());
    });
  }

  Future<void> _toggleDarkMode() async {
    final currentMode = HandyGoWorkerApp.themeModeNotifier.value;
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    HandyGoWorkerApp.themeModeNotifier.value = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'theme_mode',
      newMode == ThemeMode.dark ? 'dark' : 'light',
    );
    setState(() {}); // Rebuild to update switch state
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        WorkerModel? worker;
        if (state is Authenticated) {
          worker = state.worker;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.editProfile);
                  if (context.mounted) {
                    context.read<AuthBloc>().add(RefreshProfile());
                  }
                },
              ),
            ],
          ),
          body: worker == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusLG,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.primaryLight,
                              backgroundImage: worker.profileImage != null
                                  ? NetworkImage(worker.profileImage!)
                                  : null,
                              child: worker.profileImage == null
                                  ? Text(
                                      worker.firstName.isNotEmpty
                                          ? worker.firstName
                                                .substring(0, 1)
                                                .toUpperCase()
                                          : 'W',
                                      style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textOnPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              worker.fullName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: worker.isActive
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusRound,
                                ),
                              ),
                              child: Text(
                                worker.status.replaceAll('_', ' '),
                                style: TextStyle(
                                  color: worker.isActive
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem(
                                  context,
                                  Icons.star,
                                  worker.rating.average.toStringAsFixed(1),
                                  'Rating',
                                  AppColors.starActive,
                                ),
                                _buildStatItem(
                                  context,
                                  Icons.work,
                                  worker.totalJobsCompleted.toString(),
                                  'Jobs',
                                  AppColors.info,
                                ),
                                _buildStatItem(
                                  context,
                                  Icons.verified_user,
                                  worker.trustScore.toString(),
                                  'Trust',
                                  AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Skills Section
                      _buildSectionCard(
                        context: context,
                        title: 'Skills',
                        trailing: TextButton(
                          onPressed: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.skills,
                            );
                            if (context.mounted) {
                              context.read<AuthBloc>().add(RefreshProfile());
                            }
                          },
                          child: const Text('Manage'),
                        ),
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: worker.skills.map((skill) {
                            return Chip(
                              avatar: Icon(
                                _getSkillIcon(skill.category),
                                size: 18,
                                color: skill.isVerified
                                    ? AppColors.success
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                              ),
                              label: Text(
                                skill.category.replaceAll('_', ' '),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              backgroundColor: skill.isVerified
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : null,
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Menu Items
                      _buildMenuCard(context, [
                        _MenuItemData(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.editProfile,
                            );
                            if (context.mounted) {
                              context.read<AuthBloc>().add(RefreshProfile());
                            }
                          },
                        ),
                        _MenuItemData(
                          icon: Icons.construction,
                          title: 'Manage Skills',
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.skills,
                            );
                            if (context.mounted) {
                              context.read<AuthBloc>().add(RefreshProfile());
                            }
                          },
                        ),
                        _MenuItemData(
                          icon: Icons.account_balance_wallet,
                          title: 'Earnings',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.earnings);
                          },
                        ),
                        _MenuItemData(
                          icon: Icons.description_outlined,
                          title: 'Documents',
                          onTap: () async {
                            await Navigator.pushNamed(
                              context,
                              AppRoutes.documents,
                            );
                            if (context.mounted) {
                              context.read<AuthBloc>().add(RefreshProfile());
                            }
                          },
                        ),
                      ]),

                      const SizedBox(height: AppSpacing.md),

                      _buildMenuCard(context, [
                        _MenuItemData(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.notifications,
                            );
                          },
                        ),
                        _MenuItemData(
                          icon:
                              HandyGoWorkerApp.themeModeNotifier.value ==
                                  ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode_outlined,
                          title: 'Dark Mode',
                          isSwitch: true,
                          switchValue:
                              HandyGoWorkerApp.themeModeNotifier.value ==
                              ThemeMode.dark,
                          onTap: () => _toggleDarkMode(),
                        ),
                        _MenuItemData(
                          icon: Icons.help_outline,
                          title: 'Help & Support',
                          onTap: () {
                            _showHelpSupport(context);
                          },
                        ),
                        _MenuItemData(
                          icon: Icons.info_outline,
                          title: 'About',
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: 'Handy Go Worker',
                              applicationVersion: '1.0.0',
                              applicationLegalese:
                                  '© 2024 Handy Go. All rights reserved.',
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: AppSpacing.md),

                      _buildMenuCard(context, [
                        _MenuItemData(
                          icon: Icons.logout,
                          title: 'Logout',
                          isDestructive: true,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text(
                                  'Are you sure you want to logout?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      context.read<AuthBloc>().add(
                                        LogoutRequested(),
                                      );
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppRoutes.splash,
                                        (route) => false,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                    ),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
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
              'Help & Support',
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
                queryParameters: {'subject': 'HandyGo Worker Support Request'},
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
              final Uri waUri = Uri.parse(
                'whatsapp://send?phone=923022389814&text=Hello, I need help with HandyGo Worker app',
              );
              final Uri waBusinessUri = Uri.parse(
                'https://wa.me/923022389814?text=Hello, I need help with HandyGo Worker app',
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

  Widget _buildMenuCard(BuildContext context, List<_MenuItemData> items) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  leading: Icon(
                    item.icon,
                    color: item.isDestructive
                        ? AppColors.error
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: item.isDestructive
                          ? AppColors.error
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: item.isSwitch
                      ? Switch(
                          value: item.switchValue ?? false,
                          onChanged: (_) => item.onTap(),
                          activeThumbColor: AppColors.primary,
                        )
                      : Icon(
                          Icons.chevron_right,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  onTap: item.isSwitch ? null : item.onTap,
                ),
                if (index < items.length - 1)
                  const Divider(height: 1, indent: 56),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  IconData _getSkillIcon(String category) {
    switch (category) {
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
      default:
        return Icons.handyman;
    }
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;
  final bool isSwitch;
  final bool? switchValue;

  _MenuItemData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
    this.isSwitch = false,
    this.switchValue,
  });
}
