import '../../domain/repositories/booking_repository.dart';
import '../models/booking_model.dart';
import '../models/worker_model.dart';
import '../../presentation/blocs/booking/booking_state.dart';
import '../datasources/remote/booking_remote_datasource.dart';

/// Booking repository implementation
class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource _remoteDataSource;

  BookingRepositoryImpl({required BookingRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  @override
  Future<ProblemAnalysisResult> analyzeProblem({
    required String description,
    String? category,
  }) async {
    return await _remoteDataSource.analyzeProblem(
      description: description,
      category: category,
    );
  }

  @override
  Future<FindWorkersResult> findWorkers({
    required String serviceCategory,
    required double lat,
    required double lng,
    required DateTime scheduledDateTime,
    bool isUrgent = false,
  }) async {
    return await _remoteDataSource.findWorkers(
      serviceCategory: serviceCategory,
      lat: lat,
      lng: lng,
      scheduledDateTime: scheduledDateTime,
      isUrgent: isUrgent,
    );
  }

  @override
  Future<CreateBookingResult> createBooking(
    BookingCreateRequest request,
  ) async {
    return await _remoteDataSource.createBooking(request);
  }

  @override
  Future<String> uploadImage(String filePath) async {
    return await _remoteDataSource.uploadImage(filePath);
  }

  @override
  Future<BookingModel> selectWorker({
    required String bookingId,
    required String workerId,
  }) async {
    return await _remoteDataSource.selectWorker(
      bookingId: bookingId,
      workerId: workerId,
    );
  }

  @override
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    await _remoteDataSource.cancelBooking(bookingId: bookingId, reason: reason);
  }

  @override
  Future<BookingsListResult> getCustomerBookings({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    return await _remoteDataSource.getCustomerBookings(
      status: status,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<BookingModel> getBookingDetails(String bookingId) async {
    return await _remoteDataSource.getBookingDetails(bookingId);
  }

  @override
  Future<void> submitRating({
    required String bookingId,
    required int rating,
    String? review,
    Map<String, int>? categoryRatings,
  }) async {
    await _remoteDataSource.submitRating(
      bookingId: bookingId,
      rating: rating,
      review: review,
      categoryRatings: categoryRatings,
    );
  }

  @override
  Future<WorkerLocationResponse> getWorkerLocation(String bookingId) async {
    return await _remoteDataSource.getWorkerLocation(bookingId);
  }

  @override
  Future<SOSTriggerResult> triggerSOS({
    String? bookingId,
    required String reason,
    required String description,
    required double lat,
    required double lng,
  }) async {
    return await _remoteDataSource.triggerSOS(
      bookingId: bookingId,
      reason: reason,
      description: description,
      lat: lat,
      lng: lng,
    );
  }

  @override
  Future<PriceEstimate> estimatePrice({
    required String serviceCategory,
    required String problemDescription,
    required String city,
  }) async {
    return await _remoteDataSource.estimatePrice(
      serviceCategory: serviceCategory,
      problemDescription: problemDescription,
      city: city,
    );
  }

  @override
  Future<int> estimateDuration({
    required String serviceCategory,
    required String problemDescription,
  }) async {
    return await _remoteDataSource.estimateDuration(
      serviceCategory: serviceCategory,
      problemDescription: problemDescription,
    );
  }
}
