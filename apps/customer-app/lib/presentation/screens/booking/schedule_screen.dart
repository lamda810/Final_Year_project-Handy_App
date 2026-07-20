import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/routes/app_routes.dart';

/// Schedule selection screen for booking
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeSlot? _selectedTimeSlot;
  TimeOfDay? _selectedCustomTime;
  bool _isUrgent = false;

  // Booking context from previous screens
  Map<String, dynamic> _bookingContext = {};

  final List<DateTime> _availableDates = List.generate(
    8,
    (index) => DateTime.now().add(Duration(days: index)),
  );

  final List<TimeSlot> _timeSlots = [
    TimeSlot(
      label: 'Morning',
      description: '8:00 AM - 12:00 PM',
      icon: Icons.wb_sunny_outlined,
      startHour: 8,
      endHour: 12,
    ),
    TimeSlot(
      label: 'Afternoon',
      description: '12:00 PM - 5:00 PM',
      icon: Icons.wb_cloudy_outlined,
      startHour: 12,
      endHour: 17,
    ),
    TimeSlot(
      label: 'Evening',
      description: '5:00 PM - 9:00 PM',
      icon: Icons.nightlight_outlined,
      startHour: 17,
      endHour: 21,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _bookingContext = Map<String, dynamic>.from(args);
    }
  }

  String _getWeekDay(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String _getMonth(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Whether an hour:minute on the currently selected date would already be
  /// in the past. Used to disable stale time slots/custom times so the
  /// booking can never be submitted with a scheduledDateTime the backend
  /// will reject (it requires scheduledDateTime >= now).
  bool _isPastForSelectedDate(int hour, int minute) {
    final candidate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );
    return candidate.isBefore(DateTime.now());
  }

  Future<void> _selectCustomTime() async {
    final colorScheme = Theme.of(context).colorScheme;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now().replacing(
        hour: (TimeOfDay.now().hour + 1) % 24,
        minute: 0,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (time != null) {
      if (_isPastForSelectedDate(time.hour, time.minute)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please choose a time in the future'),
            ),
          );
        }
        return;
      }
      setState(() {
        _selectedCustomTime = time;
        _selectedTimeSlot = null;
      });
    }
  }

  void _continueBooking() {
    if (!_isUrgent &&
        _selectedTimeSlot == null &&
        _selectedCustomTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    // Build the scheduled date+time
    DateTime scheduledDateTime;
    if (_isUrgent) {
      scheduledDateTime = DateTime.now().add(const Duration(minutes: 30));
    } else if (_selectedCustomTime != null) {
      scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedCustomTime!.hour,
        _selectedCustomTime!.minute,
      );
    } else if (_selectedTimeSlot != null) {
      scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTimeSlot!.startHour,
        0,
      );
    } else {
      scheduledDateTime = DateTime.now().add(const Duration(hours: 1));
    }

    // Final guard: the backend rejects any scheduledDateTime before now.
    // The slot/date pickers above already prevent picking a past time, but
    // this catches it regardless (e.g. time elapsing while the screen was
    // open) instead of letting a doomed request reach the server.
    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date and time in the future'),
        ),
      );
      return;
    }

    Navigator.of(context).pushNamed(
      AppRoutes.workerSelection,
      arguments: {
        ..._bookingContext,
        'scheduledDateTime': scheduledDateTime.toIso8601String(),
        'isUrgent': _isUrgent,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Urgent toggle
            _buildUrgentCard(),

            if (!_isUrgent) ...[
              const SizedBox(height: AppSpacing.lg),

              // Date selection
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildDateSelector(),

              const SizedBox(height: AppSpacing.lg),

              // Time slot selection
              Text(
                'Select Time Slot',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTimeSlots(),

              const SizedBox(height: AppSpacing.md),

              // Custom time picker
              _buildCustomTimePicker(),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Summary
            _buildSummaryCard(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ElevatedButton(
            onPressed: _continueBooking,
            child: const Text('Continue'),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgentCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _isUrgent
            ? AppColors.error.withValues(alpha: 0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _isUrgent ? AppColors.error : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt,
            color: _isUrgent
                ? AppColors.error
                : colorScheme.onSurface.withValues(alpha: 0.7),
            size: 28,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need it urgently?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isUrgent ? AppColors.error : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Worker will arrive ASAP (extra charges may apply)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isUrgent
                        ? AppColors.error
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isUrgent,
            onChanged: (value) {
              setState(() {
                _isUrgent = value;
                if (value) {
                  _selectedTimeSlot = null;
                  _selectedCustomTime = null;
                }
              });
            },
            activeThumbColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableDates.length,
        itemBuilder: (context, index) {
          final date = _availableDates[index];
          final isSelected =
              _selectedDate.day == date.day &&
              _selectedDate.month == date.month;
          final isToday = _isToday(date);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                // Clear a previously-valid selection if it would now be in
                // the past on the newly selected date (e.g. switching back
                // to today after picking a slot for a future day).
                if (_selectedTimeSlot != null &&
                    _isPastForSelectedDate(_selectedTimeSlot!.startHour, 0)) {
                  _selectedTimeSlot = null;
                }
                if (_selectedCustomTime != null &&
                    _isPastForSelectedDate(
                      _selectedCustomTime!.hour,
                      _selectedCustomTime!.minute,
                    )) {
                  _selectedCustomTime = null;
                }
              });
            },
            child: Container(
              width: 70,
              margin: EdgeInsets.only(
                right: index < _availableDates.length - 1 ? AppSpacing.sm : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isToday ? 'Today' : _getWeekDay(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    _getMonth(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlots() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: _timeSlots.map((slot) {
        final isSelected = _selectedTimeSlot == slot;
        final isPast = _isPastForSelectedDate(slot.startHour, 0);

        return GestureDetector(
          onTap: isPast
              ? null
              : () {
                  setState(() {
                    _selectedTimeSlot = slot;
                    _selectedCustomTime = null;
                  });
                },
          child: Opacity(
            opacity: isPast ? 0.4 : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      slot.icon,
                      color: isSelected
                          ? AppColors.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          isPast
                              ? '${slot.description} (past)'
                              : slot.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<TimeSlot>(
                    value: slot,
                    groupValue: _selectedTimeSlot,
                    activeColor: AppColors.primary,
                    onChanged: isPast
                        ? null
                        : (TimeSlot? value) {
                            setState(() {
                              _selectedTimeSlot = value;
                              _selectedCustomTime = null;
                            });
                          },
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomTimePicker() {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCustomTime = _selectedCustomTime != null;

    return GestureDetector(
      onTap: _selectCustomTime,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: hasCustomTime
              ? AppColors.primary.withValues(alpha: 0.1)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: hasCustomTime ? AppColors.primary : AppColors.border,
            width: hasCustomTime ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: hasCustomTime
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.access_time,
                color: hasCustomTime
                    ? AppColors.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select specific time',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasCustomTime
                          ? AppColors.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    hasCustomTime
                        ? _selectedCustomTime!.format(context)
                        : 'Tap to choose a specific time',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasCustomTime
                          ? AppColors.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final colorScheme = Theme.of(context).colorScheme;
    String scheduleText;
    if (_isUrgent) {
      scheduleText = 'ASAP - Worker will be assigned immediately';
    } else if (_selectedCustomTime != null) {
      scheduleText =
          '${_getWeekDay(_selectedDate)}, ${_selectedDate.day} ${_getMonth(_selectedDate)} at ${_selectedCustomTime!.format(context)}';
    } else if (_selectedTimeSlot != null) {
      scheduleText =
          '${_getWeekDay(_selectedDate)}, ${_selectedDate.day} ${_getMonth(_selectedDate)} - ${_selectedTimeSlot!.description}';
    } else {
      scheduleText = 'Please select date and time';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppColors.info, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scheduled Time',
                  style: TextStyle(fontSize: 12, color: AppColors.info),
                ),
                const SizedBox(height: 4),
                Text(
                  scheduleText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TimeSlot {
  final String label;
  final String description;
  final IconData icon;
  final int startHour;
  final int endHour;

  TimeSlot({
    required this.label,
    required this.description,
    required this.icon,
    required this.startHour,
    required this.endHour,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;
}
