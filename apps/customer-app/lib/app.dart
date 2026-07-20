import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_navigator.dart';
import 'core/routes/app_routes.dart';
import 'core/widgets/network_aware_widget.dart';
import 'injection_container.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/blocs/booking/booking_bloc.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/blocs/notification/notification_bloc.dart';
import 'presentation/blocs/chatbot/chatbot_bloc.dart';

/// Main application widget for Handy Go Customer App
class HandyGoApp extends StatefulWidget {
  const HandyGoApp({super.key});

  // Global locale notifier for language switching
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('en'),
  );

  // Global theme mode notifier for dark mode switching
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  @override
  State<HandyGoApp> createState() => _HandyGoAppState();
}

class _HandyGoAppState extends State<HandyGoApp> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<BookingBloc>(create: (_) => sl<BookingBloc>()),
        BlocProvider<UserBloc>(create: (_) => sl<UserBloc>()),
        BlocProvider<NotificationBloc>(create: (_) => sl<NotificationBloc>()),
        BlocProvider<ChatbotBloc>(create: (_) => sl<ChatbotBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (_, __) {},
        child: ValueListenableBuilder<Locale>(
          valueListenable: HandyGoApp.localeNotifier,
          builder: (context, locale, _) {
            return ValueListenableBuilder<ThemeMode>(
              valueListenable: HandyGoApp.themeModeNotifier,
              builder: (context, themeMode, _) {
                return MaterialApp(
                  navigatorKey: appNavigatorKey,
                  title: 'Handy Go',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  locale: locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [
                    Locale('en'), // English
                    Locale('ur'), // Urdu
                  ],
                  initialRoute: AppRoutes.splash,
                  onGenerateRoute: _generateRoute,
                  builder: (context, child) {
                    // Wrap with NetworkAwareWidget for connectivity monitoring
                    return NetworkAwareWidget(
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Use the centralized router for all route generation
    return AppRouter.generateRoute(settings);
  }
}
