import '../../data/models/booking_model.dart';
import '../../data/models/worker_model.dart';
import '../../presentation/blocs/booking/booking_state.dart';

/// Problem analysis result
class ProblemAnalysisResult {
  final List<String> detectedServices;
  final double confidence;
  final List<String> suggestedQuestions;
  final String urgencyLevel;

  ProblemAnalysisResult({
    required this.detectedServices,
    required this.confidence,
    required this.suggestedQuestions,
    required this.urgencyLevel,
  });

  factory ProblemAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested { data: { detectedServices: [...] } } formats
    final dynamic rawData = json['data'];
    final Map<String, dynamic> source = (rawData is Map)
        ? Map<String, dynamic>.from(rawData)
        : json;
    return ProblemAnalysisResult(
      detectedServices: List<String>.from(
        source['detectedServices'] ?? json['detectedServices'] ?? [],
      ),
      confidence: ((source['confidence'] ?? json['confidence'] ?? 0) as num)
          .toDouble(),
      suggestedQuestions: List<String>.from(
        source['suggestedQuestions'] ?? json['suggestedQuestions'] ?? [],
      ),
      urgencyLevel: source['urgencyLevel'] ?? json['urgencyLevel'] ?? 'LOW',
    );
  }
}

/// Find workers result
class FindWorkersResult {
  final List<MatchedWorkerModel> workers;
  final int totalAvailable;
  final PriceEstimate? priceEstimate;

  FindWorkersResult({
    required this.workers,
    required this.totalAvailable,
    this.priceEstimate,
  });

  factory FindWorkersResult.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested { data: { workers: [...] } } formats
    final dynamic rawData = json['data'];
    final Map<String, dynamic> source = (rawData is Map)
        ? Map<String, dynamic>.from(rawData)
        : json;

    final dynamic workersRaw = source['workers'];
    return FindWorkersResult(
      workers: (workersRaw is List)
          ? workersRaw
                .map(
                  (w) => MatchedWorkerModel.fromJson(
                    w is Map<String, dynamic>
                        ? w
                        : Map<String, dynamic>.from(w as Map),
                  ),
                )
                .toList()
          : [],
      totalAvailable: source['totalAvailable'] ?? json['totalAvailable'] ?? 0,
      priceEstimate: (source['priceEstimate'] ?? json['priceEstimate']) != null
          ? PriceEstimate.fromJson(
              Map<String, dynamic>.from(
                (source['priceEstimate'] ?? json['priceEstimate']) as Map,
              ),
            )
          : null,
    );
  }
}

/// Create booking result
class CreateBookingResult {
  final BookingModel booking;
  final List<MatchedWorkerModel> matchedWorkers;

  CreateBookingResult({required this.booking, required this.matchedWorkers});

  factory CreateBookingResult.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested { data: { booking: ... } } formats
    final dynamic rawData = json['data'];
    final Map<String, dynamic> source = (rawData is Map)
        ? Map<String, dynamic>.from(rawData)
        : json;

    final dynamic workersRaw = source['matchedWorkers'];
    return CreateBookingResult(
      booking: BookingModel.fromJson(
        source['booking'] is Map
            ? Map<String, dynamic>.from(source['booking'] as Map)
            : (source['booking'] as Map<String, dynamic>?) ?? {},
      ),
      matchedWorkers: (workersRaw is List)
          ? workersRaw
                .map(
                  (w) => MatchedWorkerModel.fromJson(
                    w is Map<String, dynamic>
                        ? w
                        : Map<String, dynamic>.from(w as Map),
                  ),
                )
                .toList()
          : [],
    );
  }
}

/// Bookings list result
class BookingsListResult {
  final List<BookingModel> bookings;
  final int page;
  final int totalPages;
  final bool hasMore;

  BookingsListResult({
    required this.bookings,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });

  factory BookingsListResult.fromJson(Map<String, dynamic> json) {
    // Handle API response: { success: true, data: [...], meta: {...} }
    // Also handles: { data: { bookings: [...], pagination: {...} } }
    final dynamic rawData = json['data'];
    Map<String, dynamic> meta = {};
    if (json['meta'] is Map) {
      meta = Map<String, dynamic>.from(json['meta'] as Map);
    }

    // Data can be an array directly or an object with bookings key
    List<dynamic> bookingsList;
    if (rawData is List) {
      bookingsList = rawData;
    } else if (rawData is Map) {
      bookingsList = (rawData['bookings'] is List)
          ? rawData['bookings'] as List
          : [];
      // Extract pagination from nested structure if meta is empty
      if (meta.isEmpty && rawData['pagination'] is Map) {
        meta = Map<String, dynamic>.from(rawData['pagination'] as Map);
      }
    } else {
      bookingsList = [];
    }

    final page = _parseInt(meta['page']) ?? _parseInt(json['page']) ?? 1;
    final totalPages =
        _parseInt(meta['totalPages']) ?? _parseInt(json['totalPages']) ?? 1;

    return BookingsListResult(
      bookings: bookingsList
          .map(
            (b) => BookingModel.fromJson(
              b is Map<String, dynamic>
                  ? b
                  : Map<String, dynamic>.from(b as Map),
            ),
          )
          .toList(),
      page: page,
      totalPages: totalPages,
      hasMore: page < totalPages,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }
}

/// SOS trigger result
class SOSTriggerResult {
  final String sosId;
  final String priority;

  SOSTriggerResult({required this.sosId, required this.priority});

  factory SOSTriggerResult.fromJson(Map<String, dynamic> json) {
    // Handle both flat and nested { data: { sosId: ... } } formats
    final dynamic rawData = json['data'];
    final Map<String, dynamic> source = (rawData is Map)
        ? Map<String, dynamic>.from(rawData)
        : json;
    return SOSTriggerResult(
      sosId:
          source['sosId'] ??
          source['_id'] ??
          json['sosId'] ??
          json['_id'] ??
          '',
      priority: source['priority'] ?? json['priority'] ?? 'MEDIUM',
    );
  }
}

/// Abstract booking repository interface
abstract class BookingRepository {
  /// Analyze problem description using AI
  Future<ProblemAnalysisResult> analyzeProblem({
    required String description,
    String? category,
  });

  /// Find available workers for a service
  Future<FindWorkersResult> findWorkers({
    required String serviceCategory,
    required double lat,
    required double lng,
    required DateTime scheduledDateTime,
    bool isUrgent = false,
  });

  /// Create a new booking
  Future<CreateBookingResult> createBooking(BookingCreateRequest request);

  /// Upload a local image file and return its server-hosted URL.
  Future<String> uploadImage(String filePath);

  /// Select a worker for booking
  Future<BookingModel> selectWorker({
    required String bookingId,
    required String workerId,
  });

  /// Cancel a booking
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
  });

  /// Get customer bookings
  Future<BookingsListResult> getCustomerBookings({
    String? status,
    int page = 1,
    int limit = 10,
  });

  /// Get booking details
  Future<BookingModel> getBookingDetails(String bookingId);

  /// Submit rating for booking
  Future<void> submitRating({
    required String bookingId,
    required int rating,
    String? review,
    Map<String, int>? categoryRatings,
  });

  /// Get worker location for tracking
  Future<WorkerLocationResponse> getWorkerLocation(String bookingId);

  /// Trigger SOS alert
  Future<SOSTriggerResult> triggerSOS({
    String? bookingId,
    required String reason,
    required String description,
    required double lat,
    required double lng,
  });

  /// Get price estimate
  Future<PriceEstimate> estimatePrice({
    required String serviceCategory,
    required String problemDescription,
    required String city,
  });

  /// Get duration estimate
  Future<int> estimateDuration({
    required String serviceCategory,
    required String problemDescription,
  });
}
