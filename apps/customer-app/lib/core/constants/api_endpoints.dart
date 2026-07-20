/// API endpoints for Handy Go backend services
class ApiEndpoints {
  ApiEndpoints._();

  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Deployed backend on Render — stable, no ngrok/tunnel needed anymore.
  // To point at a local backend instead, run with
  // --dart-define=API_BASE_URL=http://localhost:3000/api (or 10.0.2.2 for
  // the Android emulator) rather than editing this constant.
  static const String _renderBaseUrl =
      'https://final-year-project-handy-app.onrender.com/api';

  static String get _defaultLocalBaseUrl => _renderBaseUrl;

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
