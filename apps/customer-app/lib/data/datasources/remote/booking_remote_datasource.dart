import '../../models/booking_model.dart';
import '../../models/worker_model.dart';
import '../../../domain/repositories/booking_repository.dart';
import '../../../presentation/blocs/booking/booking_state.dart';

/// Remote data source for booking operations
abstract class BookingRemoteDataSource {
  Future<ProblemAnalysisResult> analyzeProblem({
    required String description,
    String? category,
  });

  Future<FindWorkersResult> findWorkers({
    required String serviceCategory,
    required double lat,
    required double lng,
    required DateTime scheduledDateTime,
    bool isUrgent,
  });

  Future<CreateBookingResult> createBooking(BookingCreateRequest request);

  Future<BookingModel> selectWorker({
    required String bookingId,
    required String workerId,
  });

  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
  });

  Future<BookingsListResult> getCustomerBookings({
    String? status,
    int page,
    int limit,
  });

  Future<BookingModel> getBookingDetails(String bookingId);

  Future<void> submitRating({
    required String bookingId,
    required int rating,
    String? review,
    Map<String, int>? categoryRatings,
  });

  Future<WorkerLocationResponse> getWorkerLocation(String bookingId);

  Future<SOSTriggerResult> triggerSOS({
    String? bookingId,
    required String reason,
    required String description,
    required double lat,
    required double lng,
  });

  Future<PriceEstimate> estimatePrice({
    required String serviceCategory,
    required String problemDescription,
    required String city,
  });

  Future<int> estimateDuration({
    required String serviceCategory,
    required String problemDescription,
  });

  /// Upload a local image file and return its server-hosted URL.
  Future<String> uploadImage(String filePath);
}
