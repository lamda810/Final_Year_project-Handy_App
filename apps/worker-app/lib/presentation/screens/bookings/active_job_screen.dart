import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/string_extensions.dart';
import '../../../core/widgets/photo_strip.dart';
import '../../../data/models/booking_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../injection_container.dart';
import '../../routes/app_routes.dart';

class ActiveJobScreen extends StatefulWidget {
  final String bookingId;

  const ActiveJobScreen({super.key, required this.bookingId});

  @override
  State<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends State<ActiveJobScreen> {
  final BookingRepository _repository = sl<BookingRepository>();
  final LocationService _locationService = LocationService();
  BookingModel? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  Timer? _durationTimer;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    // Don't stop location tracking here — it will be stopped when
    // the job is completed/cancelled via the LocationService.
    _statusPollTimer?.cancel();
    super.dispose();
  }

  /// Poll the booking status so customer-side changes (e.g. cancellation)
  /// are picked up without realtime infrastructure.
  void _startStatusPolling() {
    _statusPollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted || _isProcessing) return;
      try {
        final booking = await _repository.getBookingDetails(widget.bookingId);
        if (!mounted) return;

        // If the booking was cancelled, show alert and pop
        if (booking.isCancelled) {
          _statusPollTimer?.cancel();
          _durationTimer?.cancel();
          _locationService.stopActiveJobTracking(resumeIdle: true);
          _repository.resetWorkerAvailability(); // Fire-and-forget
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This booking has been cancelled'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context, true);
          return;
        }

        setState(() => _booking = booking);
      } catch (_) {
        // Polling is best-effort; ignore transient errors
      }
    });
  }

  Future<void> _loadBooking() async {
    try {
      final booking = await _repository.getBookingDetails(widget.bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });

      // If job is in progress, start the timer
      if (booking.isInProgress) {
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _startTime = DateTime.now();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_startTime ?? DateTime.now());
      });
    });
    // Start active job location tracking via the centralized service
    _locationService.startActiveJobTracking(widget.bookingId);
  }

  Future<void> _startJob() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final booking = await _repository.startBooking(widget.bookingId);
      setState(() {
        _booking = booking;
        _isProcessing = false;
      });
      _startTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job started!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to start job'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _completeJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _CompleteJobDialog(
        estimatedPrice: _booking?.pricing.estimatedPrice ?? 0,
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Price was already decided at booking creation — the worker no
      // longer enters a final amount here; the backend uses the
      // booking's estimatedPrice when finalPrice is omitted.
      await _repository.completeBooking(widget.bookingId);

      _durationTimer?.cancel();
      _locationService.stopActiveJobTracking(resumeIdle: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job completed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to complete job: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Job'),
        actions: [
          // SOS Button
          IconButton(
            icon: const Icon(Icons.sos, color: AppColors.error),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.sos,
                arguments: {
                  // Backend does Booking.findById(bookingId) — needs the
                  // real Mongo _id, not the human-readable booking number.
                  'bookingId': booking?.id,
                  'customerName': booking?.customer.fullName,
                  'customerPhone': booking?.customer.callablePhone,
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : booking == null
          ? const Center(child: Text('Booking not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: booking.isInProgress
                          ? LinearGradient(
                              colors: [
                                AppColors.statusInProgress,
                                AppColors.statusInProgress.withValues(
                                  alpha: 0.8,
                                ),
                              ],
                            )
                          : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLG),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          booking.isInProgress
                              ? Icons.timer
                              : Icons.play_circle_outline,
                          size: 48,
                          color: AppColors.textOnPrimary,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          booking.isInProgress
                              ? 'Job In Progress'
                              : 'Ready to Start',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        if (booking.isInProgress) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _formatDuration(_elapsedTime),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnPrimary,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            'Duration',
                            style: TextStyle(
                              color: AppColors.textOnPrimary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Service Info
                  Card(
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSM,
                          ),
                        ),
                        child: Icon(
                          _getServiceIcon(booking.serviceCategory),
                          color: AppColors.primary,
                        ),
                      ),
                      title: Text(
                        booking.serviceCategory.replaceAll('_', ' '),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(booking.bookingNumber),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Customer Card
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.secondaryDark,
                        child: Text(
                          booking.customer.firstName.initial('C'),
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(booking.customer.fullName),
                      subtitle: Text(booking.customer.callablePhone ?? 'No phone available'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          IconButton(
                            icon: const Icon(Icons.message),
                            color: AppColors.secondary,
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.chat,
                                arguments: {
                                  // Chat API requires the real Mongo _id,
                                  // not the human-readable booking number.
                                  'bookingId': booking.id,
                                  'bookingNumber': booking.bookingNumber,
                                  'customerName': booking.customer.fullName,
                                  'customerPhone': booking.customer.callablePhone,
                                },
                              );
                            },
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
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(child: Text(booking.address.full)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final coords = booking.address.coordinates;
                                launchUrl(
                                  Uri.parse(
                                    'https://www.google.com/maps/dir/?api=1&destination=${coords.lat},${coords.lng}',
                                  ),
                                );
                              },
                              icon: const Icon(Icons.navigation),
                              label: const Text('Navigate'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Problem Description
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Problem Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              booking.problemDescription,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
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
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  if (booking.isAccepted)
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _startJob,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Start Job'),
                    )
                  else if (booking.isInProgress)
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _completeJob,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Icon(Icons.check_circle),
                      label: const Text('Complete Job'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
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

class _CompleteJobDialog extends StatelessWidget {
  final double estimatedPrice;

  const _CompleteJobDialog({required this.estimatedPrice});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Job'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mark this job as completed?',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Amount: Rs. ${estimatedPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Complete'),
        ),
      ],
    );
  }
}
