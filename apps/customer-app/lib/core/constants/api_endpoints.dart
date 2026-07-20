import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// API endpoints for Handy Go backend services
class ApiEndpoints {
  ApiEndpoints._();

  // ========================================================
  // DEPLOYMENT CONFIGURATION
  // ========================================================
  // Choose ONE of these options:

  // Option 1: Local Development (Android Emulator)
  // static const String _host = '10.0.2.2';

  // Option 2: Physical Device (replace with your PC's IP)
  // Run: ipconfig | findstr IPv4
  // static const String _host = '192.168.1.100';

  // Option 3: ngrok tunnel (for remote testing)
  // static const String _host = 'your-subdomain.ngrok.io';
  // static const bool _useHttps = true;

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

  static String get baseUrl {
    return _configuredBaseUrl.isNotEmpty ? _configuredBaseUrl : _defaultLocalBaseUrl;
  }

  // Auth endpoints
  static const String sendOTP = '/auth/send-otp';
  static const String verifyOTP = '/auth/verify-otp';
  static const String registerCustomer = '/auth/register/customer';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Customer profile endpoints
  static const String customerProfile = '/users/customer/profile';
  static const String customerAddresses = '/users/customer/addresses';
  static const String deleteAccount = '/users/customer/account';

  // Booking endpoints
  static const String bookings = '/bookings';
  static const String createBooking = '/bookings';
  static const String customerBookings = '/bookings/customer';
  static String bookingDetails(String id) => '/bookings/$id';
  static String selectWorker(String id) => '/bookings/$id/select-worker';
  static String cancelBooking(String id) => '/bookings/$id/cancel';
  static String rateBooking(String id) => '/bookings/$id/rate';
  static String bookingMessages(String id) => '/bookings/$id/messages';

  // Matching endpoints
  static const String analyzeProblem = '/matching/analyze-problem';
  static const String findWorkers = '/matching/find-workers';
  static const String estimatePrice = '/matching/estimate-price';
  static const String estimateDuration = '/matching/estimate-duration';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static const String markAsRead = '/notifications/read-all';
  static const String registerDevice = '/notifications/register-device';
  static const String unregisterDevice = '/notifications/unregister-device';

  // SOS endpoints
  static const String triggerSOS = '/sos/trigger';
  static String sosDetails(String id) => '/sos/$id';
  static String updateSos(String id) => '/sos/$id/update';

  // Timeouts
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
