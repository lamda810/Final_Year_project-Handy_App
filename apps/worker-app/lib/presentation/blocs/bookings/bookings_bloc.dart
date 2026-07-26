import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/error_mapper.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'bookings_event.dart';
import 'bookings_state.dart';

/// Manages the full booking lifecycle from the worker's perspective:
/// listing, accepting, starting, completing, and GPS updates.
class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final BookingRepository _bookingRepo;

  BookingsBloc({required BookingRepository bookingRepository})
    : _bookingRepo = bookingRepository,
      super(const BookingsInitial()) {
    on<BookingsLoadRequested>(_onLoad);
    on<BookingAccepted>(_onAccept);
    on<BookingRejected>(_onReject);
    on<BookingStarted>(_onStart);
    on<BookingCompleted>(_onComplete);
    on<BookingLocationUpdated>(_onLocationUpdate);
  }

  Future<void> _onLoad(
    BookingsLoadRequested event,
    Emitter<BookingsState> emit,
  ) async {
    emit(const BookingsLoading());
    try {
      final bookings = await _bookingRepo.getWorkerBookings(
        status: event.status,
        page: event.page,
      );
      emit(BookingsLoaded(bookings: bookings, activeFilter: event.status));
    } catch (e) {
      emit(BookingsError(ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onAccept(
    BookingAccepted event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingActionInProgress(event.bookingId));
    try {
      final booking = await _bookingRepo.acceptBooking(event.bookingId);
      emit(BookingActionSuccess(booking, 'accepted'));
    } catch (e) {
      emit(BookingsError(ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onReject(
    BookingRejected event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingActionInProgress(event.bookingId));
    try {
      await _bookingRepo.rejectBooking(event.bookingId, event.reason);
      // Reload the list after rejection
      add(const BookingsLoadRequested());
    } catch (e) {
      emit(BookingsError(ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onStart(
    BookingStarted event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingActionInProgress(event.bookingId));
    try {
      final booking = await _bookingRepo.startBooking(
        event.bookingId,
        otpCode: event.otpCode,
        beforeImages: event.beforeImages,
      );
      emit(BookingActionSuccess(booking, 'started'));
    } catch (e) {
      emit(BookingsError(ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onComplete(
    BookingCompleted event,
    Emitter<BookingsState> emit,
  ) async {
    emit(BookingActionInProgress(event.bookingId));
    try {
      final booking = await _bookingRepo.completeBooking(
        event.bookingId,
        otpCode: event.otpCode,
        afterImages: event.afterImages,
        finalPrice: event.finalPrice,
        materialsCost: event.materialsCost,
      );
      emit(BookingActionSuccess(booking, 'completed'));
    } catch (e) {
      emit(BookingsError(ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onLocationUpdate(
    BookingLocationUpdated event,
    Emitter<BookingsState> emit,
  ) async {
    // Fire-and-forget — don't change state for GPS pings
    try {
      await _bookingRepo.updateBookingLocation(
        event.bookingId,
        event.lat,
        event.lng,
      );
    } catch (_) {
      // Silently ignore location update failures
    }
  }
}
