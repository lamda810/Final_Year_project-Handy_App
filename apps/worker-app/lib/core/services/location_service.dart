import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/worker_repository.dart';
import '../../injection_container.dart';

/// Centralized location service for the worker app.
///
/// Handles two modes:
/// 1. **Idle tracking** — when the worker is available, periodically updates
///    the worker profile's `currentLatitude`/`currentLongitude` so the matching
///    service can find them.
/// 2. **Active job tracking** — during an in-progress booking, sends frequent
///    location pings to the `worker_location_history` collection so the
///    customer can track the worker in real time.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final WorkerRepository _workerRepo = sl<WorkerRepository>();
  final BookingRepository _bookingRepo = sl<BookingRepository>();

  Timer? _idleTimer;
  Timer? _activeJobTimer;
  String? _activeBookingId;
  bool _isTracking = false;

  /// Whether the service is currently tracking the worker's location.
  bool get isTracking => _isTracking;

  /// The booking ID currently being tracked, if any.
  String? get activeBookingId => _activeBookingId;

  // ─── Permission Helpers ──────────────────────────────────────────────

  /// Requests location permission. Returns `true` if granted.
  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Returns the current position, or `null` if unavailable.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Idle Tracking (Worker is Available) ─────────────────────────────

  /// Start periodic location updates to the worker profile.
  /// Called when the worker toggles availability ON.
  /// Updates every 60 seconds.
  void startIdleTracking() {
    stopIdleTracking(); // Prevent duplicate timers
    _isTracking = true;

    // Send immediately, then every 60 seconds
    _updateWorkerProfileLocation();
    _idleTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _updateWorkerProfileLocation();
    });
  }

  /// Stop idle location tracking.
  /// Called when the worker toggles availability OFF or starts an active job.
  void stopIdleTracking() {
    _idleTimer?.cancel();
    _idleTimer = null;
    if (_activeBookingId == null) _isTracking = false;
  }

  Future<void> _updateWorkerProfileLocation() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return;

      await _workerRepo.updateLocation(position.latitude, position.longitude);
    } catch (_) {
      // Best-effort — don't crash the app for location failures
    }
  }

  // ─── Active Job Tracking (During In-Progress Booking) ────────────────

  /// Start sending location pings for a specific booking.
  /// Updates every 30 seconds to the `worker_location_history` collection
  /// AND the worker profile.
  void startActiveJobTracking(String bookingId) {
    stopActiveJobTracking(); // Clear any previous
    stopIdleTracking(); // Pause idle tracking while on a job

    _activeBookingId = bookingId;
    _isTracking = true;

    // Send immediately, then every 30 seconds
    _sendJobLocationUpdate();
    _activeJobTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendJobLocationUpdate();
    });
  }

  /// Stop active job location tracking.
  /// Called when the job is completed or cancelled.
  /// Optionally resumes idle tracking if `resumeIdle` is true.
  void stopActiveJobTracking({bool resumeIdle = false}) {
    _activeJobTimer?.cancel();
    _activeJobTimer = null;
    _activeBookingId = null;

    if (resumeIdle) {
      startIdleTracking();
    } else {
      _isTracking = false;
    }
  }

  Future<void> _sendJobLocationUpdate() async {
    try {
      final position = await getCurrentPosition();
      if (position == null) return;

      final bookingId = _activeBookingId;
      if (bookingId == null) return;

      // Update both the booking history and the worker profile in parallel
      await Future.wait([
        _bookingRepo.updateBookingLocation(
          bookingId,
          position.latitude,
          position.longitude,
        ),
        _workerRepo.updateLocation(position.latitude, position.longitude),
      ]);
    } catch (_) {
      // Best-effort — don't crash the app for location failures
    }
  }

  // ─── Cleanup ─────────────────────────────────────────────────────────

  /// Stop all tracking. Call when the user logs out.
  void stopAll() {
    stopIdleTracking();
    stopActiveJobTracking();
  }
}
