import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/booking_model.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/booking/booking_event.dart';
import '../../blocs/booking/booking_state.dart';

/// Bookings list screen showing all customer bookings
class BookingsListScreen extends StatefulWidget {
  const BookingsListScreen({super.key});

  @override
  State<BookingsListScreen> createState() => _BookingsListScreenState();
}

class _BookingsListScreenState extends State<BookingsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<BookingModel> _activeBookings = [];
  List<BookingModel> _pastBookings = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
    // Poll so a status change made by the worker (accept/reject/start/
    // complete) shows up while this list is open, not just on manual
    // refresh or when a booking happens to be cancelled from here.
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadBookings(silent: true);
    });
  }

  void _loadBookings({bool silent = false}) {
    // Set our own loading flag directly rather than reacting to the shared
    // bloc's generic BookingLoading state (see listener below for why). A
    // silent (polling) refresh skips the full-screen spinner so it doesn't
    // interrupt the user browsing the list.
    if (!silent) setState(() => _isLoading = true);
    context.read<BookingBloc>().add(const LoadBookingsRequested(limit: 50));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return AppColors.warning;
      case BookingStatus.accepted:
        return AppColors.info;
      case BookingStatus.inProgress:
        return AppColors.secondary;
      case BookingStatus.completed:
        return AppColors.success;
      case BookingStatus.cancelled:
        return AppColors.error;
      case BookingStatus.disputed:
        return AppColors.error;
    }
  }

  String _getStatusText(BookingStatus status) {
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingsLoaded) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
            // Separate active and past bookings
            _activeBookings = state.bookings
                .where(
                  (b) =>
                      b.status == BookingStatus.pending ||
                      b.status == BookingStatus.accepted ||
                      b.status == BookingStatus.inProgress,
                )
                .toList();
            _pastBookings = state.bookings
                .where(
                  (b) =>
                      b.status == BookingStatus.completed ||
                      b.status == BookingStatus.cancelled ||
                      b.status == BookingStatus.disputed,
                )
                .toList();
          });
        } else if (state is BookingError) {
          setState(() {
            _isLoading = false;
            _errorMessage = state.message;
          });
        } else if (state is BookingCancelled) {
          // A booking may have been cancelled from the tracking screen
          // (this screen stays mounted underneath that push). Refresh so
          // the list reflects the cancellation instead of going stale.
          _loadBookings();
        }
        // Deliberately not reacting to the generic BookingLoading state:
        // it's emitted by unrelated actions on this shared bloc (cancel,
        // rating submission, detail loads, ...) and would otherwise flip
        // this screen into a loading state that only BookingsLoaded/
        // BookingError (both handled above) can clear — if neither ever
        // arrives (e.g. the action was a cancel, not a list reload), the
        // spinner would be stuck forever.
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.bookings),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBookings,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Active (${_activeBookings.length})'),
              Tab(text: 'Past (${_pastBookings.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorView()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingsList(_activeBookings, isActive: true),
                  _buildBookingsList(_pastBookings, isActive: false),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            _errorMessage ?? 'An error occurred',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _onPullToRefresh() async {
    _loadBookings();
    // Wait for this refresh's own result so the indicator stays visible
    // until the list has actually updated, rather than vanishing early.
    await context.read<BookingBloc>().stream.firstWhere(
      (state) => state is BookingsLoaded || state is BookingError,
    );
  }

  Widget _buildBookingsList(
    List<BookingModel> bookings, {
    required bool isActive,
  }) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: ListView(
          // Empty-state content isn't tall enough to scroll on its own;
          // force scrollability so the pull-to-refresh gesture still works.
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? Icons.event_busy : Icons.history,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      isActive ? 'No active bookings' : 'No past bookings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      isActive
                          ? 'Book a service to get started'
                          : 'Your completed bookings will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onPullToRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index], isActive);
        },
      ),
    );
  }

  Widget _buildBookingCard(BookingModel booking, bool isActive) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);
    final workerName = booking.worker?.firstName != null
        ? '${booking.worker!.firstName} ${booking.worker?.lastName ?? ''}'
              .trim()
        : 'Pending Assignment';

    return GestureDetector(
      onTap: () {
        if (isActive) {
          Navigator.of(context).pushNamed(
            AppRoutes.bookingTracking,
            arguments: {'bookingId': booking.id},
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    booking.bookingNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: AppSpacing.lg),

            // Service info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.build,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        () {
                          final text =
                              '${booking.serviceCategory} - ${booking.problemDescription}';
                          return text.length > 40
                              ? '${text.substring(0, 40)}...'
                              : text;
                        }(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        workerName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Bottom row
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(booking.scheduledDateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  'Rs. ${booking.pricing.estimatedPrice?.toStringAsFixed(0) ?? booking.pricing.finalPrice?.toStringAsFixed(0) ?? 'TBD'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            // Rating for completed bookings
            if (booking.rating != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.star, color: AppColors.ratingStar, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    booking.rating!.score.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    ' - Your rating',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],

            // Action button for active bookings
            if (isActive) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.bookingTracking,
                      arguments: {'bookingId': booking.id},
                    );
                  },
                  child: const Text('Track Booking'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0 && date.day == now.day) {
      return 'Today, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == -1 ||
        (diff.inDays == 0 && date.day == now.day + 1)) {
      return 'Tomorrow, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
