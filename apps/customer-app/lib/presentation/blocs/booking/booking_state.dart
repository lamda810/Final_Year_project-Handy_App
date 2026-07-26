import 'package:equatable/equatable.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/worker_model.dart';

/// Base booking state
abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// Initial booking state
class BookingInitial extends BookingState {
  const BookingInitial();
}

/// Loading state
class BookingLoading extends BookingState {
  final String? message;

  const BookingLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// Problem analyzed state
class ProblemAnalyzed extends BookingState {
  final List<String> detectedServices;
  final double confidence;
  final List<String> suggestedQuestions;
  final String urgencyLevel;

  const ProblemAnalyzed({
    required this.detectedServices,
    required this.confidence,
    required this.suggestedQuestions,
    required this.urgencyLevel,
  });

  @override
  List<Object?> get props => [
    detectedServices,
    confidence,
    suggestedQuestions,
    urgencyLevel,
  ];
}

/// Workers found state
class WorkersFound extends BookingState {
  final List<MatchedWorkerModel> workers;
  final int totalAvailable;
  final PriceEstimate? priceEstimate;

  const WorkersFound({
    required this.workers,
    required this.totalAvailable,
    this.priceEstimate,
  });

  @override
  List<Object?> get props => [workers, totalAvailable, priceEstimate];
}

/// Booking created state
class BookingCreated extends BookingState {
  final BookingModel booking;
  final List<MatchedWorkerModel> matchedWorkers;

  const BookingCreated({required this.booking, required this.matchedWorkers});

  @override
  List<Object?> get props => [booking, matchedWorkers];
}

/// Worker selected state
class WorkerSelected extends BookingState {
  final BookingModel booking;

  const WorkerSelected({required this.booking});

  @override
  List<Object?> get props => [booking];
}

/// Bookings loaded state
class BookingsLoaded extends BookingState {
  final List<BookingModel> bookings;
  final int page;
  final int totalPages;
  final bool hasMore;

  const BookingsLoaded({
    required this.bookings,
    required this.page,
    required this.totalPages,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [bookings, page, totalPages, hasMore];
}

/// Booking details loaded state
class BookingDetailsLoaded extends BookingState {
  final BookingModel booking;

  const BookingDetailsLoaded({required this.booking});

  @override
  List<Object?> get props => [booking];
}

/// Booking cancelled state
class BookingCancelled extends BookingState {
  final String bookingId;
  final String message;

  const BookingCancelled({required this.bookingId, required this.message});

  @override
  List<Object?> get props => [bookingId, message];
}

/// Rating submitted state
class RatingSubmitted extends BookingState {
  final String bookingId;

  const RatingSubmitted({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

/// Booking location updated (tracking)
class BookingLocationUpdated extends BookingState {
  final String bookingId;
  final double lat;
  final double lng;
  final int? etaMinutes;

  const BookingLocationUpdated({
    required this.bookingId,
    required this.lat,
    required this.lng,
    this.etaMinutes,
  });

  @override
  List<Object?> get props => [bookingId, lat, lng, etaMinutes];
}

/// Job-start/job-end OTP generated, ready to show the customer
class JobOtpRevealed extends BookingState {
  final String code;
  final String purpose;
  final DateTime expiresAt;

  const JobOtpRevealed({
    required this.code,
    required this.purpose,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [code, purpose, expiresAt];
}

/// SOS triggered state
class SOSTriggered extends BookingState {
  final String sosId;
  final String priority;

  const SOSTriggered({required this.sosId, required this.priority});

  @override
  List<Object?> get props => [sosId, priority];
}

/// Booking error state
class BookingError extends BookingState {
  final String message;
  final String? errorCode;

  const BookingError({required this.message, this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}

/// Price estimate model
class PriceEstimate extends Equatable {
  final double min;
  final double max;
  final double average;
  final double laborCostMin;
  final double laborCostMax;
  final double estimatedMaterialsMin;
  final double estimatedMaterialsMax;
  final double platformFee;

  const PriceEstimate({
    required this.min,
    required this.max,
    required this.average,
    required this.laborCostMin,
    required this.laborCostMax,
    required this.estimatedMaterialsMin,
    required this.estimatedMaterialsMax,
    required this.platformFee,
  });

  factory PriceEstimate.fromJson(Map<String, dynamic> json) {
    final estimated = json['estimatedPrice'] ?? {};
    final breakdown = json['breakdown'] ?? {};
    final labor = breakdown['laborCost'] ?? {};
    final materials = breakdown['estimatedMaterials'] ?? {};

    return PriceEstimate(
      min: (estimated['min'] ?? 0).toDouble(),
      max: (estimated['max'] ?? 0).toDouble(),
      average: (estimated['average'] ?? 0).toDouble(),
      laborCostMin: (labor['min'] ?? 0).toDouble(),
      laborCostMax: (labor['max'] ?? 0).toDouble(),
      estimatedMaterialsMin: (materials['min'] ?? 0).toDouble(),
      estimatedMaterialsMax: (materials['max'] ?? 0).toDouble(),
      platformFee: (breakdown['platformFee'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    min,
    max,
    average,
    laborCostMin,
    laborCostMax,
    estimatedMaterialsMin,
    estimatedMaterialsMax,
    platformFee,
  ];
}
