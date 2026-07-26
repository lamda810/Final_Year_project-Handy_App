import '../../data/models/booking_model.dart';

/// Abstract contract for booking operations available to a worker.
///
/// Concrete implementation: `AppwriteBookingRepository`.
abstract class BookingRepository {
  /// Bookings in the worker's area that have not yet been accepted.
  Future<List<BookingModel>> getAvailableBookings();

  /// Bookings assigned to the authenticated worker, optionally filtered by
  /// [status] (e.g. `'IN_PROGRESS'`, `'COMPLETED'`).
  Future<List<BookingModel>> getWorkerBookings({
    String? status,
    int page = 1,
    int limit = 10,
  });

  /// Full details for a single booking.
  Future<BookingModel> getBookingDetails(String bookingId);

  /// Accept an available booking. Returns the updated booking.
  Future<BookingModel> acceptBooking(String bookingId);

  /// Reject / decline an available booking with a [reason].
  Future<void> rejectBooking(String bookingId, String reason);

  /// Mark an accepted booking as started (IN_PROGRESS). [otpCode] is the
  /// code the customer reads aloud to the worker, verified server-side.
  Future<BookingModel> startBooking(
    String bookingId, {
    required String otpCode,
    List<String>? beforeImages,
  });

  /// Mark a booking as completed. [otpCode] is the code the customer reads
  /// aloud to the worker, verified server-side. Optionally attach
  /// after-images and final cost.
  Future<BookingModel> completeBooking(
    String bookingId, {
    required String otpCode,
    List<String>? afterImages,
    double? finalPrice,
    double? materialsCost,
  });

  /// Push the worker's live GPS coordinates for an active booking.
  Future<void> updateBookingLocation(String bookingId, double lat, double lng);

  /// Reset the worker's in-booking flag so they appear available again
  /// (e.g. after a crash recovery).
  Future<void> resetWorkerAvailability();

  /// Realtime stream of new bookings assigned to [workerId].
  Stream<Map<String, dynamic>> subscribeToNewBookings(String workerId);

  /// Realtime stream of status changes on a specific booking.
  Stream<Map<String, dynamic>> subscribeToBookingUpdates(String bookingId);
}
