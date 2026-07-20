import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/error_mapper.dart';
import '../../../domain/repositories/booking_repository.dart';
import 'booking_event.dart';
import 'booking_state.dart';

/// Booking BLoC for managing booking flow state
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;

  BookingBloc({required BookingRepository bookingRepository})
    : _bookingRepository = bookingRepository,
      super(const BookingInitial()) {
    on<AnalyzeProblemRequested>(_onAnalyzeProblem);
    on<FindWorkersRequested>(_onFindWorkers);
    on<CreateBookingRequested>(_onCreateBooking);
    on<SelectWorkerRequested>(_onSelectWorker);
    on<CancelBookingRequested>(_onCancelBooking);
    on<LoadBookingsRequested>(_onLoadBookings);
    on<LoadBookingDetailsRequested>(_onLoadBookingDetails);
    on<SubmitRatingRequested>(_onSubmitRating);
    on<UpdateBookingLocationRequested>(_onUpdateBookingLocation);
    on<TriggerSOSRequested>(_onTriggerSOS);
  }

  Future<void> _onAnalyzeProblem(
    AnalyzeProblemRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Analyzing your problem...'));

    try {
      final result = await _bookingRepository.analyzeProblem(
        description: event.description,
        category: event.category,
      );
      emit(
        ProblemAnalyzed(
          detectedServices: result.detectedServices,
          confidence: result.confidence,
          suggestedQuestions: result.suggestedQuestions,
          urgencyLevel: result.urgencyLevel,
        ),
      );
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onFindWorkers(
    FindWorkersRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Finding available workers...'));

    try {
      final result = await _bookingRepository.findWorkers(
        serviceCategory: event.serviceCategory,
        lat: event.lat,
        lng: event.lng,
        scheduledDateTime: event.scheduledDateTime,
        isUrgent: event.isUrgent,
      );
      emit(
        WorkersFound(
          workers: result.workers,
          totalAvailable: result.totalAvailable,
          priceEstimate: result.priceEstimate,
        ),
      );
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onCreateBooking(
    CreateBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Creating your booking...'));

    try {
      var request = event.request;
      if (request.images != null && request.images!.isNotEmpty) {
        emit(const BookingLoading(message: 'Uploading photos...'));
        // request.images arrive as local device file paths (picked via
        // image_picker) — upload each one and swap in the server URL,
        // since a local path is meaningless to anyone but this device.
        final uploadedUrls = <String>[];
        for (final path in request.images!) {
          uploadedUrls.add(await _bookingRepository.uploadImage(path));
        }
        request = request.copyWith(images: uploadedUrls);
        emit(const BookingLoading(message: 'Creating your booking...'));
      }

      final result = await _bookingRepository.createBooking(request);
      emit(
        BookingCreated(
          booking: result.booking,
          matchedWorkers: result.matchedWorkers,
        ),
      );
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onSelectWorker(
    SelectWorkerRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Assigning worker...'));

    try {
      final booking = await _bookingRepository.selectWorker(
        bookingId: event.bookingId,
        workerId: event.workerId,
      );
      emit(WorkerSelected(booking: booking));
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onCancelBooking(
    CancelBookingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Cancelling booking...'));

    try {
      await _bookingRepository.cancelBooking(
        bookingId: event.bookingId,
        reason: event.reason,
      );
      emit(
        BookingCancelled(
          bookingId: event.bookingId,
          message: 'Booking cancelled successfully',
        ),
      );
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onLoadBookings(
    LoadBookingsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Loading bookings...'));

    try {
      final result = await _bookingRepository.getCustomerBookings(
        status: event.status,
        page: event.page,
        limit: event.limit,
      );
      emit(
        BookingsLoaded(
          bookings: result.bookings,
          page: result.page,
          totalPages: result.totalPages,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onLoadBookingDetails(
    LoadBookingDetailsRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Loading booking details...'));

    try {
      final booking = await _bookingRepository.getBookingDetails(
        event.bookingId,
      );
      emit(BookingDetailsLoaded(booking: booking));
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onSubmitRating(
    SubmitRatingRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Submitting rating...'));

    try {
      await _bookingRepository.submitRating(
        bookingId: event.bookingId,
        rating: event.rating,
        review: event.review,
        categoryRatings: event.categoryRatings,
      );
      emit(RatingSubmitted(bookingId: event.bookingId));
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }

  Future<void> _onUpdateBookingLocation(
    UpdateBookingLocationRequested event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final location = await _bookingRepository.getWorkerLocation(
        event.bookingId,
      );
      emit(
        BookingLocationUpdated(
          bookingId: event.bookingId,
          lat: location.lat,
          lng: location.lng,
          etaMinutes: location.etaMinutes,
        ),
      );
    } catch (e) {
      // Silent fail for location updates
    }
  }

  Future<void> _onTriggerSOS(
    TriggerSOSRequested event,
    Emitter<BookingState> emit,
  ) async {
    emit(const BookingLoading(message: 'Sending SOS alert...'));

    try {
      final result = await _bookingRepository.triggerSOS(
        bookingId: event.bookingId,
        reason: event.reason,
        description: event.description,
        lat: event.lat,
        lng: event.lng,
      );
      emit(SOSTriggered(sosId: result.sosId, priority: result.priority));
    } catch (e) {
      emit(BookingError(message: ErrorMapper.toUserMessage(e)));
    }
  }
}
