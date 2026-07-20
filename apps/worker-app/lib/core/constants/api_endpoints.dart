import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // ngrok tunnel to the local backend (port 3000), used for testing on a
  // real device over WiFi instead of the Android emulator's 10.0.2.2 alias.
  // Free-tier ngrok URLs change every time the tunnel restarts — if
  // requests stop reaching the backend, get the current URL from
  // `curl http://localhost:4040/api/tunnels` and update this constant.
  static const String _ngrokBaseUrl =
      'https://turniplike-snarkily-alita.ngrok-free.dev/api';

  static String get _defaultLocalBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (Platform.isAndroid) {
      return _ngrokBaseUrl;
    }

    return 'http://localhost:3000/api';
  }

  static String get baseUrl =>
      _configuredBaseUrl.isNotEmpty ? _configuredBaseUrl : _defaultLocalBaseUrl;

  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String registerWorker = '/auth/register/worker';
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
 
  // Worker Profile Endpoints
  static const String workerProfile = '/users/worker/profile';
  static const String updateLocation = '/users/worker/location';
  static const String updateAvailability = '/users/worker/availability';
  static const String uploadDocuments = '/users/worker/documents';
  static const String workerEarnings = '/users/worker/earnings';

  // Booking Endpoints
  // Worker actions live under /bookings/worker/... on the booking service.
  static const String availableBookings = '/bookings/worker/available';
  static const String workerBookings = '/bookings/worker';
  static String acceptBooking(String id) => '/bookings/worker/$id/accept';
  static String rejectBooking(String id) => '/bookings/worker/$id/reject';
  static String startBooking(String id) => '/bookings/worker/$id/start';
  static String completeBooking(String id) => '/bookings/worker/$id/complete';
  static String bookingLocation(String id) => '/bookings/worker/$id/location';
  static String bookingDetails(String id) => '/bookings/$id';
  static String bookingMessages(String id) => '/bookings/$id/messages';

  // Notification Endpoints
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static const String registerDevice = '/notifications/register-device';
  static String markAsRead(String id) => '/notifications/$id/read';
  static const String markAllAsRead = '/notifications/read-all';

  // SOS Endpoints
  static const String triggerSos = '/sos/trigger';
  static String sosDetails(String id) => '/sos/$id';
}
