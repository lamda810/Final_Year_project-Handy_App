import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/booking_model.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/booking/booking_event.dart';
import '../../blocs/booking/booking_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_state.dart';
import '../../blocs/user/user_bloc.dart';
import '../../blocs/user/user_state.dart';
import '../../widgets/service_category_card.dart';
import 'main_screen.dart';

/// Home screen with service categories and quick actions
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ServiceCategory> _categories = [
    ServiceCategory(
      name: AppStrings.plumbing,
      icon: Icons.plumbing,
      imagePath: 'assets/images/plumbing.png',
      color: AppColors.plumbing,
      route: AppRoutes.serviceSelection,
    ),
    ServiceCategory(
      name: AppStrings.electrical,
      icon: Icons.electrical_services,
      imagePath: 'assets/images/electrical.png',
      color: AppColors.electrical,
      route: AppRoutes.serviceSelection,
    ),
    ServiceCategory(
      name: AppStrings.cleaning,
      icon: Icons.cleaning_services,
      imagePath: 'assets/images/cleaning.png',
      color: AppColors.cleaning,
      route: AppRoutes.serviceSelection,
    ),
    ServiceCategory(
      name: AppStrings.acRepair,
      icon: Icons.ac_unit,
      imagePath: 'assets/images/acrepair.png',
      color: AppColors.acRepair,
      route: AppRoutes.serviceSelection,
    ),
    ServiceCategory(
      name: AppStrings.carpenter,
      icon: Icons.carpenter,
      imagePath: 'assets/images/carpenter.png',
      color: AppColors.carpenter,
      route: AppRoutes.serviceSelection,
    ),
    ServiceCategory(
      name: AppStrings.painting,
      icon: Icons.format_paint,
      imagePath: 'assets/images/painting.png',
      color: AppColors.painting,
      route: AppRoutes.serviceSelection,
    ),
    ServiceCategory(
      name: AppStrings.mechanic,
      icon: Icons.build,
      imagePath: 'assets/images/mechanic.png',
      color: AppColors.mechanic,
      route: AppRoutes.serviceSelection,
    ),
    ServiceCategory(
      name: AppStrings.handyman,
      icon: Icons.handyman,
      imagePath: 'assets/images/handyman.png',
      color: AppColors.handyman,
      route: AppRoutes.serviceSelection,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentBookings();
  }

  void _loadRecentBookings() {
    context.read<BookingBloc>().add(const LoadBookingsRequested(status: 'all'));
  }

  Future<void> _onRefresh() async {
    _loadRecentBookings();
    // Wait for this refresh's own result so the pull-to-refresh indicator
    // stays visible until the recent-bookings section actually updates.
    await context.read<BookingBloc>().stream.firstWhere(
      (state) => state is BookingsLoaded || state is BookingError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            slivers: [
            // App bar with location and notifications
            SliverToBoxAdapter(child: _buildAppBar()),

            // Search bar
            SliverToBoxAdapter(child: _buildSearchBar()),

            // Service categories header
            SliverToBoxAdapter(
              child: _buildSectionHeader(AppStrings.serviceCategories),
            ),

            // Service categories grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final category = _categories[index];
                  return ServiceCategoryCard(
                    category: category,
                    onTap: () => _onCategoryTap(category),
                  );
                }, childCount: _categories.length),
              ),
            ),

            // Recent bookings header
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                AppStrings.recentBookings,
                showSeeAll: true,
                onSeeAll: () {
                  // Navigate to bookings tab (index 1)
                  final mainScreenState = context
                      .findAncestorStateOfType<MainScreenState>();
                  if (mainScreenState != null) {
                    mainScreenState.switchToTab(1);
                  }
                },
              ),
            ),

            // Recent bookings list
            SliverToBoxAdapter(child: _buildRecentBookings()),

            // Promotional banners
            SliverToBoxAdapter(child: _buildPromoBanner()),
            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Location selector
          Expanded(
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                String locationText = 'Select Location';
                if (state is UserProfileLoaded && state.addresses.isNotEmpty) {
                  final defaultAddress = state.addresses.firstWhere(
                    (a) => a.isDefault,
                    orElse: () => state.addresses.first,
                  );
                  locationText =
                      '${defaultAddress.address}, ${defaultAddress.city}';
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.savedAddresses);
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    locationText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: colorScheme.onSurface,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Notification button with real badge
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int unreadCount = 0;
              if (state is NotificationLoaded) {
                unreadCount = state.unreadCount;
              }

              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      // Switch to notifications tab (index 2)
                      final mainScreenState = context
                          .findAncestorStateOfType<MainScreenState>();
                      if (mainScreenState != null) {
                        mainScreenState.switchToTab(2);
                      }
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    color: colorScheme.onSurface,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          // Profile avatar
          GestureDetector(
            onTap: () {
              // Switch to profile tab (index 3)
              final mainScreenState = context
                  .findAncestorStateOfType<MainScreenState>();
              if (mainScreenState != null) {
                mainScreenState.switchToTab(3);
              }
            },
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                String? profileImage;
                String initials = 'U';

                if (state is UserProfileLoaded) {
                  profileImage = state.profile.profileImage;
                  final first = state.profile.firstName.isNotEmpty
                      ? state.profile.firstName[0]
                      : '';
                  final last = state.profile.lastName.isNotEmpty
                      ? state.profile.lastName[0]
                      : '';
                  initials = '$first$last'.toUpperCase();
                  if (initials.isEmpty) initials = 'U';
                }

                return CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: profileImage != null
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          // Navigate to search screen
          Navigator.of(context).pushNamed(AppRoutes.search);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppStrings.searchHint,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    bool showSeeAll = false,
    VoidCallback? onSeeAll,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          if (showSeeAll)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'See All',
                style: TextStyle(fontSize: 14, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocBuilder<BookingBloc, BookingState>(
      buildWhen: (previous, current) =>
          current is BookingsLoaded || current is BookingError,
      builder: (context, state) {
        List<BookingModel> bookings = [];

        if (state is BookingsLoaded) {
          bookings = state.bookings.take(3).toList();
        }

        if (bookings.isEmpty) {
          return Container(
            height: 160,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 36,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'No recent bookings',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Book a service to get started',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking, index, bookings.length);
            },
          ),
        );
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking, int index, int total) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(booking.status);
    final categoryIcon = _getCategoryIcon(booking.serviceCategory);
    final categoryColor = _getCategoryColor(booking.serviceCategory);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.bookingTracking,
          arguments: {'bookingId': booking.id},
        );
      },
      child: Container(
        width: 280,
        margin: EdgeInsets.only(right: index < total - 1 ? AppSpacing.md : 0),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(categoryIcon, color: categoryColor, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatCategoryName(booking.serviceCategory),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        booking.bookingNumber.isNotEmpty
                            ? booking.bookingNumber
                            : booking.id.substring(0, 8),
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                  child: Text(
                    _formatStatus(booking.status),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              _formatBookingDate(booking),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.inProgress:
        return AppColors.info;
      case BookingStatus.accepted:
        return AppColors.primary;
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.cancelled:
      case BookingStatus.disputed:
        return AppColors.error;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toUpperCase()) {
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
        return Icons.home_repair_service;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'PLUMBING':
        return AppColors.plumbing;
      case 'ELECTRICAL':
        return AppColors.electrical;
      case 'CLEANING':
        return AppColors.cleaning;
      case 'AC_REPAIR':
        return AppColors.acRepair;
      case 'CARPENTER':
        return AppColors.carpenter;
      case 'PAINTING':
        return AppColors.painting;
      case 'MECHANIC':
        return AppColors.mechanic;
      case 'GENERAL_HANDYMAN':
        return AppColors.handyman;
      default:
        return AppColors.primary;
    }
  }

  String _formatCategoryName(String category) {
    return category
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '',
        )
        .join(' ');
  }

  String _formatStatus(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.disputed:
        return 'Disputed';
    }
  }

  String _formatBookingDate(BookingModel booking) {
    final date = booking.scheduledDateTime;

    final now = DateTime.now();
    final diff = now.difference(date);

    String dateStr;
    if (diff.inDays == 0) {
      dateStr = 'Today';
    } else if (diff.inDays == 1) {
      dateStr = 'Yesterday';
    } else if (diff.inDays < 7) {
      dateStr = '${diff.inDays} days ago';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    final price = booking.pricing.finalPrice ?? booking.pricing.estimatedPrice;
    if (price != null) {
      return '$dateStr • Rs. ${price.toStringAsFixed(0)}';
    }
    return dateStr;
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      height: 140,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Find trusted workers near you',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Text(
                    'Book Now →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onCategoryTap(ServiceCategory category) {
    Navigator.of(
      context,
    ).pushNamed(category.route, arguments: {'category': category.name});
  }
}
