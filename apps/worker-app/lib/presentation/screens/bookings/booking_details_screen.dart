import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/string_extensions.dart';
import '../../../core/widgets/photo_strip.dart';
import '../../../data/models/booking_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../injection_container.dart';
import '../../routes/app_routes.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final BookingRepository _repository = sl<BookingRepository>();
  BookingModel? _booking;
  bool _isLoading = true;
  bool _isAccepting = false;
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    super.dispose();
  }

  /// Poll the booking so customer-side changes (e.g. cancellation or
  /// reassignment while the worker is reviewing) are picked up.
  void _startStatusPolling() {
    _statusPollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted || _isAccepting) return;
      try {
        final booking = await _repository.getBookingDetails(widget.bookingId);
        if (!mounted) return;
        if (_bounceIfCancelled(booking)) return;
        setState(() => _booking = booking);
      } catch (_) {
        // Polling is best-effort; ignore transient errors
      }
    });
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await _repository.getBookingDetails(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
      // The booking may already have been cancelled before this screen was
      // ever opened (e.g. tapped from a stale, not-yet-refreshed list) —
      // check on the very first load too, not just while polling.
      _bounceIfCancelled(booking);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load booking details'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// If [booking] is cancelled, tell the worker and leave this screen.
  /// Returns true if it bounced (caller should not proceed to use the
  /// booking further).
  bool _bounceIfCancelled(BookingModel booking) {
    if (!booking.isCancelled) return false;
    _statusPollTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This booking has been cancelled by the customer'),
        backgroundColor: AppColors.error,
      ),
    );
    Navigator.pop(context);
    return true;
  }

  Future<void> _acceptBooking() async {
    setState(() {
      _isAccepting = true;
    });

    try {
      final booking = await _repository.acceptBooking(widget.bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking accepted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.activeJob,
          arguments: booking.id,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to accept booking'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isAccepting = false;
      });
    }
  }

  Future<void> _rejectBooking() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _repository.rejectBooking(widget.bookingId, reason);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Booking rejected')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject booking'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      appBar: AppBar(title: Text(booking?.bookingNumber ?? 'Booking Details')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
          ? const Center(child: Text('Booking not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  if (booking.isUrgent)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMD,
                        ),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.error,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            'URGENT REQUEST',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.md),

                  // Service Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMD,
                                  ),
                                ),
                                child: Icon(
                                  _getServiceIcon(booking.serviceCategory),
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.serviceCategory.replaceAll(
                                        '_',
                                        ' ',
                                      ),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Booking: ${booking.bookingNumber}',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Divider(),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Problem Description',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            booking.problemDescription,
                            style: const TextStyle(fontSize: 15),
                          ),
                          if (booking.beforeImages != null &&
                              booking.beforeImages!.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Photos from Customer',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            PhotoStrip(imageUrls: booking.beforeImages!),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Customer Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Customer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.secondary,
                                child: Text(
                                  booking.customer.firstName.initial('C'),
                                  style: const TextStyle(
                                    color: AppColors.textOnPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.customer.fullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      booking.customer.callablePhone ?? 'No phone available',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone),
                                color: AppColors.primary,
                                onPressed: () {
                                  final phone = booking.customer.callablePhone;
                                  if (phone != null && phone.isNotEmpty) {
                                    launchUrl(Uri.parse('tel:$phone'));
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Location Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.address.full,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      booking.address.city,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          OutlinedButton.icon(
                            onPressed: () {
                              final coords = booking.address.coordinates;
                              launchUrl(
                                Uri.parse(
                                  'https://www.google.com/maps/dir/?api=1&destination=${coords.lat},${coords.lng}',
                                ),
                              );
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Pricing Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Pricing',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _buildPriceRow(
                            'Labor Cost',
                            booking.pricing.laborCost?.toStringAsFixed(0) ??
                                '---',
                          ),
                          _buildPriceRow(
                            'Estimated Duration',
                            '${booking.estimatedDuration ?? 60} mins',
                          ),
                          const Divider(),
                          _buildPriceRow(
                            'Estimated Total',
                            'Rs. ${booking.pricing.estimatedPrice?.toStringAsFixed(0) ?? '---'}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  if (booking.isPending) ...[
                    ElevatedButton(
                      onPressed: _isAccepting ? null : _acceptBooking,
                      child: _isAccepting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Text('Accept Job'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: _rejectBooking,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Reject'),
                    ),
                  ] else
                    // Reached via a stale card tap (e.g. a job that was
                    // already accepted/started/completed elsewhere before
                    // this screen's data caught up) — explain why there's
                    // no Accept/Reject instead of leaving a silent gap.
                    _buildNonActionableStatusBanner(booking),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }

  Widget _buildNonActionableStatusBanner(BookingModel booking) {
    late final IconData icon;
    late final Color color;
    late final String message;

    if (booking.isCancelled) {
      icon = Icons.cancel_outlined;
      color = AppColors.error;
      message = 'This job has been cancelled by the customer.';
    } else if (booking.isCompleted) {
      icon = Icons.check_circle_outline;
      color = AppColors.success;
      message = 'This job has already been completed.';
    } else if (booking.isInProgress) {
      icon = Icons.build_circle_outlined;
      color = AppColors.primary;
      message = 'This job is already in progress.';
    } else {
      // Accepted, or accepted by someone else while this screen was open.
      icon = Icons.info_outline;
      color = AppColors.primary;
      message = 'This job has already been accepted and is no longer '
          'awaiting a response.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMD),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold
                  ? AppColors.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String category) {
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

class _RejectDialog extends StatefulWidget {
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please provide a reason for rejecting this job:'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter reason...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
