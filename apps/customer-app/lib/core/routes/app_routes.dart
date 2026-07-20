import 'package:flutter/material.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/email_input_screen.dart';
import '../../presentation/screens/auth/otp_verification_screen.dart';
import '../../presentation/screens/auth/registration_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/auth/reset_password_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/main_screen.dart';
import '../../presentation/screens/home/search_screen.dart';
import '../../presentation/screens/booking/service_selection_screen.dart';
import '../../presentation/screens/booking/location_selection_screen.dart';
import '../../presentation/screens/booking/schedule_screen.dart';
import '../../presentation/screens/booking/worker_selection_screen.dart';
import '../../presentation/screens/booking/booking_confirmation_screen.dart';
import '../../presentation/screens/booking/booking_tracking_screen.dart';
import '../../presentation/screens/booking/rating_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/sos/sos_screen.dart';
import '../../presentation/screens/profile/terms_screen.dart';
import '../../presentation/screens/profile/privacy_policy_screen.dart';
import '../../presentation/screens/profile/notification_settings_screen.dart';
import '../../presentation/screens/profile/wallet_screen.dart';
import '../../presentation/screens/profile/payment_methods_screen.dart';
import '../../presentation/screens/profile/saved_addresses_screen.dart';
import '../../presentation/screens/chat/ai_assistant_screen.dart';

/// App route names
class AppRoutes {
  AppRoutes._();

  // Auth routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String emailInput = '/email-input';
  static const String otpVerification = '/otp-verification';
  static const String registration = '/registration';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main routes
  static const String main = '/main';
  static const String home = '/home';
  static const String search = '/search';

  // Booking routes
  static const String serviceSelection = '/booking/service-selection';
  static const String locationSelection = '/booking/location-selection';
  static const String schedule = '/booking/schedule';
  static const String workerSelection = '/booking/worker-selection';
  static const String bookingConfirmation = '/booking/confirmation';
  static const String bookingTracking = '/booking/tracking';
  static const String rating = '/booking/rating';
  static const String chat = '/chat';
  static const String aiAssistant = '/ai-assistant';
  static const String sos = '/sos';

  // Profile routes
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String addresses = '/profile/addresses';
  static const String savedAddresses = '/profile/saved-addresses';
  static const String paymentMethods = '/profile/payment-methods';
  static const String wallet = '/profile/wallet';
  static const String bookings = '/bookings';
  static const String bookingDetails = '/bookings/details';

  // Settings routes
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/settings/notifications';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';
  static const String help = '/help';
}

/// Route generator
class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth routes
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);

      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);

      case AppRoutes.emailInput:
        return _buildRoute(const EmailInputScreen(), settings);

      case AppRoutes.otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          OtpVerificationScreen(
            email: args?['email'] ?? '',
            purpose: args?['purpose'] ?? 'REGISTRATION',
          ),
          settings,
        );

      case AppRoutes.registration:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          RegistrationScreen(
            email: args?['email'] ?? '',
            tempToken: args?['tempToken'] ?? '',
          ),
          settings,
        );

      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);

      case AppRoutes.forgotPassword:
        return _buildRoute(const ForgotPasswordScreen(), settings);

      case AppRoutes.resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ResetPasswordScreen(
            tempToken: args?['tempToken'] ?? '',
            email: args?['email'] ?? '',
          ),
          settings,
        );

      // Main routes
      case AppRoutes.main:
        return _buildRoute(const MainScreen(), settings);

      case AppRoutes.home:
        return _buildRoute(const HomeScreen(), settings);

      case AppRoutes.search:
        return _buildRoute(const SearchScreen(), settings);

      // Booking routes
      case AppRoutes.serviceSelection:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ServiceSelectionScreen(category: args?['category'] ?? ''),
          settings,
        );

      case AppRoutes.locationSelection:
        return _buildRoute(const LocationSelectionScreen(), settings);

      case AppRoutes.schedule:
        return _buildRoute(const ScheduleScreen(), settings);

      case AppRoutes.workerSelection:
        return _buildRoute(const WorkerSelectionScreen(), settings);

      case AppRoutes.bookingConfirmation:
        return _buildRoute(const BookingConfirmationScreen(), settings);

      case AppRoutes.bookingTracking:
        return _buildRoute(const BookingTrackingScreen(), settings);

      case AppRoutes.rating:
        return _buildRoute(const RatingScreen(), settings);

      case AppRoutes.chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ChatScreen(
            bookingId: args?['bookingId'] ?? '',
            workerName: args?['workerName'] ?? 'Worker',
            workerPhone: args?['workerPhone'] ?? '',
          ),
          settings,
        );

      case AppRoutes.aiAssistant:
        return _buildRoute(const AIAssistantScreen(), settings);

      case AppRoutes.sos:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          SOSScreen(
            bookingId: args?['bookingId'],
            workerName: args?['workerName'],
            workerPhone: args?['workerPhone'],
          ),
          settings,
        );

      // Profile routes
      case AppRoutes.savedAddresses:
        return _buildRoute(const SavedAddressesScreen(), settings);

      case AppRoutes.paymentMethods:
        return _buildRoute(const PaymentMethodsScreen(), settings);

      case AppRoutes.wallet:
        return _buildRoute(const WalletScreen(), settings);

      case AppRoutes.termsConditions:
        return _buildRoute(const TermsScreen(), settings);

      case AppRoutes.privacyPolicy:
        return _buildRoute(const PrivacyPolicyScreen(), settings);

      case AppRoutes.notificationSettings:
        return _buildRoute(const NotificationSettingsScreen(), settings);

      // Default route
      default:
        return _buildRoute(
          Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }
}
