import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'home_screen.dart';
import '../bookings/bookings_list_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _lastBackPressTime;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingsListScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  List<BottomNavItem> _buildNavItems(AppLocalizations l10n) {
    return [
      BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: l10n.home,
      ),
      BottomNavItem(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: l10n.bookings,
      ),
      BottomNavItem(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        label: l10n.notifications,
      ),
      BottomNavItem(
        icon: Icons.person_outlined,
        activeIcon: Icons.person,
        label: l10n.profile,
      ),
    ];
  }

  /// Public method to switch tabs programmatically
  void switchToTab(int index) {
    if (index >= 0 && index < _screens.length) {
      setState(() => _currentIndex = index);
    }
  }

  /// Handle back button press with double-tap to exit
  Future<bool> _onWillPop() async {
    // If not on home tab, go to home tab first
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }

    // Double back press logic
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Press back again to exit'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          margin: const EdgeInsets.all(AppSpacing.md),
        ),
      );
      return false;
    }

    // Exit the app
    SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final navItems = _buildNavItems(l10n);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: AppSpacing.bottomNavHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  navItems.length,
                  (index) => _buildNavItem(index, navItems),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, List<BottomNavItem> navItems) {
    final item = navItems[index];
    final isSelected = _currentIndex == index;
    final isNotifications = index == 2;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 24,
                ),
                if (isNotifications)
                  BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      int unreadCount = 0;
                      if (state is NotificationLoaded) {
                        unreadCount = state.unreadCount;
                      }
                      if (unreadCount == 0) return const SizedBox.shrink();

                      return Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
