import 'package:equatable/equatable.dart';

/// Events for [BookingsBloc].
abstract class BookingsEvent extends Equatable {
  const BookingsEvent();
  @override
  List<Object?> get props => [];
}

/// Load all bookings for the worker, optionally by [status].
class BookingsLoadRequested extends BookingsEvent {
  final String? status;
  final int page;
  const BookingsLoadRequested({this.status, this.page = 1});
  @override
  List<Object?> get props => [status, page];
}

/// Accept an available booking.
class BookingAccepted extends BookingsEvent {
  final String bookingId;
  const BookingAccepted(this.bookingId);
  @override
  List<Object?> get props => [bookingId];
}

/// Reject an available booking.
class BookingRejected extends BookingsEvent {
  final String bookingId;
  final String reason;
  const BookingRejected(this.bookingId, this.reason);
  @override
  List<Object?> get props => [bookingId, reason];
}

/// Start working on an accepted booking. [otpCode] is the code the
/// customer reads aloud to the worker, verified server-side.
class BookingStarted extends BookingsEvent {
  final String bookingId;
  final String otpCode;
  final List<String>? beforeImages;
  const BookingStarted(this.bookingId, {required this.otpCode, this.beforeImages});
  @override
  List<Object?> get props => [bookingId, otpCode, beforeImages];
}

/// Complete a booking. [otpCode] is the code the customer reads aloud to
/// the worker, verified server-side.
class BookingCompleted extends BookingsEvent {
  final String bookingId;
  final String otpCode;
  final List<String>? afterImages;
  final double? finalPrice;
  final double? materialsCost;
  const BookingCompleted(
    this.bookingId, {
    required this.otpCode,
    this.afterImages,
    this.finalPrice,
    this.materialsCost,
  });
  @override
  List<Object?> get props => [
    bookingId,
    otpCode,
    afterImages,
    finalPrice,
    materialsCost,
  ];
}

/// Push live GPS for an active booking.
class BookingLocationUpdated extends BookingsEvent {
  final String bookingId;
  final double lat;
  final double lng;
  const BookingLocationUpdated(this.bookingId, this.lat, this.lng);
  @override
  List<Object?> get props => [bookingId, lat, lng];
}
