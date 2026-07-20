import 'package:flutter/material.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/email_input_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/bookings/booking_details_screen.dart';
import '../screens/bookings/active_job_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/skills_screen.dart';
import '../screens/profile/documents_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/sos/sos_screen.dart';

class AppRoutes {
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String emailInput = '/email-input';
  static const String otpVerification = '/otp-verification';
  static const String registration = '/registration';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Main Routes
  static const String home = '/home';
  static const String bookingDetails = '/booking-details';
  static const String activeJob = '/active-job';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String skills = '/skills';
  static const String documents = '/documents';
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String sos = '/sos';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case emailInput:
        return MaterialPageRoute(builder: (_) => const EmailInputScreen());

      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            phone: args?['phone'] ?? '',
            purpose: args?['purpose'] ?? 'REGISTRATION',
          ),
        );

      case registration:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RegistrationScreen(
            tempToken: args?['tempToken'] ?? '',
            phone: args?['phone'] ?? '',
          ),
        );

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case resetPassword:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            tempToken: args?['tempToken'] ?? '',
            phone: args?['phone'] ?? '',
          ),
        );

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case bookingDetails:
        final bookingId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => BookingDetailsScreen(bookingId: bookingId ?? ''),
        );

      case activeJob:
        final bookingId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ActiveJobScreen(bookingId: bookingId ?? ''),
        );

      case earnings:
        return MaterialPageRoute(builder: (_) => const EarningsScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case skills:
        return MaterialPageRoute(builder: (_) => const SkillsScreen());

      case documents:
        return MaterialPageRoute(builder: (_) => const DocumentsScreen());

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            bookingId: args?['bookingId'] ?? '',
            bookingNumber: args?['bookingNumber'],
            customerName: args?['customerName'] ?? '',
            customerPhone: args?['customerPhone'] ?? '',
          ),
        );

      case sos:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => SOSScreen(
            bookingId: args?['bookingId'],
            customerName: args?['customerName'],
            customerPhone: args?['customerPhone'],
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
