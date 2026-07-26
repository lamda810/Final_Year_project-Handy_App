import 'package:equatable/equatable.dart';
import '../../../data/models/booking_model.dart';

/// Base booking event
abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to analyze problem description
class AnalyzeProblemRequested extends BookingEvent {
  final String description;
  final String? category;

  const AnalyzeProblemRequested({required this.description, this.category});

  @override
  List<Object?> get props => [description, category];
}

/// Event to find available workers
class FindWorkersRequested extends BookingEvent {
  final String serviceCategory;
  final double lat;
  final double lng;
  final DateTime scheduledDateTime;
  final bool isUrgent;

  const FindWorkersRequested({
    required this.serviceCategory,
    required this.lat,
    required this.lng,
    required this.scheduledDateTime,
    this.isUrgent = false,
  });

  @override
  List<Object?> get props => [
    serviceCategory,
    lat,
    lng,
    scheduledDateTime,
    isUrgent,
  ];
}

/// Event to create a new booking
class CreateBookingRequested extends BookingEvent {
  final BookingCreateRequest request;

  const CreateBookingRequested({required this.request});

  @override
  List<Object?> get props => [request];
}

/// Event to select a worker for booking
class SelectWorkerRequested extends BookingEvent {
  final String bookingId;
  final String workerId;

  const SelectWorkerRequested({
    required this.bookingId,
    required this.workerId,
  });

  @override
  List<Object?> get props => [bookingId, workerId];
}

/// Event to cancel a booking
class CancelBookingRequested extends BookingEvent {
  final String bookingId;
  final String reason;

  const CancelBookingRequested({required this.bookingId, required this.reason});

  @override
  List<Object?> get props => [bookingId, reason];
}

/// Event to load customer bookings
class LoadBookingsRequested extends BookingEvent {
  final String? status;
  final int page;
  final int limit;

  const LoadBookingsRequested({this.status, this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [status, page, limit];
}

/// Event to load single booking details
class LoadBookingDetailsRequested extends BookingEvent {
  final String bookingId;

  const LoadBookingDetailsRequested({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

/// Event to submit rating for a booking
class SubmitRatingRequested extends BookingEvent {
  final String bookingId;
  final int rating;
  final String? review;
  final Map<String, int>? categoryRatings;

  const SubmitRatingRequested({
    required this.bookingId,
    required this.rating,
    this.review,
    this.categoryRatings,
  });

  @override
  List<Object?> get props => [bookingId, rating, review, categoryRatings];
}

/// Event to update booking location (tracking)
class UpdateBookingLocationRequested extends BookingEvent {
  final String bookingId;

  const UpdateBookingLocationRequested({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

/// Event to generate/reveal the job-start or job-end OTP so the customer
/// can read it aloud to the worker.
class RevealJobOtpRequested extends BookingEvent {
  final String bookingId;
  final String purpose; // 'JOB_START' or 'JOB_END'

  const RevealJobOtpRequested({required this.bookingId, required this.purpose});

  @override
  List<Object?> get props => [bookingId, purpose];
}

/// Event to trigger SOS
class TriggerSOSRequested extends BookingEvent {
  final String? bookingId;
  final String reason;
  final String description;
  final double lat;
  final double lng;

  const TriggerSOSRequested({
    this.bookingId,
    required this.reason,
    required this.description,
    required this.lat,
    required this.lng,
  });

  @override
  List<Object?> get props => [bookingId, reason, description, lat, lng];
}
