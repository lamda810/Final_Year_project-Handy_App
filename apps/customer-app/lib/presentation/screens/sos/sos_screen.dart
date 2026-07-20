import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../blocs/booking/booking_bloc.dart';
import '../../blocs/booking/booking_event.dart';
import '../../blocs/booking/booking_state.dart';

/// Emergency SOS Screen for customers
class SOSScreen extends StatefulWidget {
  final String? bookingId;
  final String? workerName;
  final String? workerPhone;

  const SOSScreen({
    super.key,
    this.bookingId,
    this.workerName,
    this.workerPhone,
  });

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> with TickerProviderStateMixin {
  String? _selectedReason;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCountingDown = false;
  bool _isSubmitting = false;
  int _countdown = 5;
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Evidence images
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _evidenceImages = [];

  final List<String> _sosReasons = [
    'Feeling unsafe',
    'Aggressive behavior',
    'Threat or violence',
    'Harassment',
    'Dispute',
    'Medical emergency',
    'Property damage',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a reason for the emergency'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isCountingDown = true;
      _countdown = 5;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });
        if (_countdown <= 0) {
          timer.cancel();
          _triggerSOS();
        }
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdown = 5;
    });
  }

  Future<void> _pickEvidence() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (picked != null && _evidenceImages.length < 3) {
        setState(() => _evidenceImages.add(picked));
      }
    } catch (_) {
      // Image picker cancelled or errored
    }
  }

  void _removeEvidence(int index) {
    setState(() => _evidenceImages.removeAt(index));
  }

  Future<void> _callWorker() async {
    final phone = widget.workerPhone;
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker phone number not available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _triggerSOS() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    // TODO: Upload evidence images once the backend exposes a storage
    // endpoint. For now the count is noted in the SOS description and the
    // photos stay on the device.

    // Get current location
    double lat = 0.0;
    double lng = 0.0;
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {
      // Fallback - send with 0,0 so SOS still goes through
    }

    if (!mounted) return;

    context.read<BookingBloc>().add(
      TriggerSOSRequested(
        bookingId: widget.bookingId,
        reason: _selectedReason ?? 'Other',
        description:
            _descriptionController.text.trim() +
            (_evidenceImages.isNotEmpty
                ? '\n\n[Evidence: ${_evidenceImages.length} image(s) captured on device]'
                : ''),
        lat: lat,
        lng: lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is SOSTriggered) {
          setState(() => _isSubmitting = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🚨 SOS Alert Sent! (Priority: ${state.priority}) Our team will contact you shortly.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (!context.mounted) return;
            Navigator.of(context).pop();
          });
        } else if (state is BookingError) {
          setState(() {
            _isSubmitting = false;
            _isCountingDown = false;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send SOS: ${state.message}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _isCountingDown
            ? AppColors.error
            : colorScheme.surfaceContainerHighest,
        appBar: _isCountingDown ? null : _buildAppBar(),
        body: SafeArea(
          child: _isCountingDown ? _buildCountdownView() : _buildMainContent(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.error,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textOnPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'Emergency SOS',
        style: TextStyle(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildMainContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Warning banner
          Container(
            width: double.infinity,
            color: AppColors.error,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.textOnPrimary,
                  size: 48,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Are you in an emergency?',
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Our team will be notified immediately and will contact you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textOnPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking context
                if (widget.bookingId != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking: ${widget.bookingId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (widget.workerName != null)
                                Text(
                                  'Worker: ${widget.workerName}',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.workerPhone != null &&
                            widget.workerPhone!.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: _callWorker,
                            icon: const Icon(Icons.call, size: 18),
                            label: const Text('Call Worker'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Reason selection
                Text(
                  'What\'s happening?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: _sosReasons.map((reason) {
                    final isSelected = _selectedReason == reason;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedReason = reason),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.error
                              : colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.error
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          reason,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textOnPrimary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Description
                Text(
                  'Additional details (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe the situation...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(AppSpacing.md),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Evidence upload section
                Text(
                  'Attach evidence (optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_evidenceImages.isNotEmpty) ...[
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _evidenceImages.length,
                      separatorBuilder: (_, i) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_evidenceImages[index].path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, st) => Container(
                                  width: 80,
                                  height: 80,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.image,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeEvidence(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: AppColors.textOnPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (_evidenceImages.length < 3)
                  OutlinedButton.icon(
                    onPressed: _pickEvidence,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: Text(
                      _evidenceImages.isEmpty
                          ? 'Add photo/video evidence'
                          : 'Add more (${_evidenceImages.length}/3)',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withValues(
                        alpha: 0.7,
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),

                const SizedBox(height: AppSpacing.xl),

                // SOS Button
                Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: GestureDetector(
                      onTap: _startCountdown,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.error.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sos,
                                color: AppColors.textOnPrimary,
                                size: 48,
                              ),
                              SizedBox(height: AppSpacing.xs),
                              Text(
                                'SEND SOS',
                                style: TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Emergency contacts
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildEmergencyContact(
                        'Police',
                        '15',
                        Icons.local_police,
                      ),
                      _buildEmergencyContact(
                        'Rescue',
                        '1122',
                        Icons.medical_services,
                      ),
                      _buildEmergencyContact(
                        'Fire',
                        '16',
                        Icons.local_fire_department,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String name, String number, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            name,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling $name: $number'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.textOnPrimary,
            size: 80,
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Sending SOS in',
            style: TextStyle(color: AppColors.textOnPrimary, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$_countdown',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 100,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Reason: $_selectedReason',
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Your location will be shared with our emergency team',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textOnPrimary, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.xxl),
          OutlinedButton(
            onPressed: _cancelCountdown,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.textOnPrimary, width: 2),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
