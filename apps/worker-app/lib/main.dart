import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_colors.dart';
import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/booking_repository.dart';
import 'domain/repositories/worker_repository.dart';
import 'injection_container.dart';
import 'l10n/generated/app_localizations.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/auth/auth_state.dart';
import 'presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register all dependencies via get_it
  initDependencies();

  // Load saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode');
  if (savedTheme == 'dark') {
    HandyGoWorkerApp.themeModeNotifier.value = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    HandyGoWorkerApp.themeModeNotifier.value = ThemeMode.light;
  }

  // Load saved locale preference
  final savedLocale = prefs.getString('locale');
  if (savedLocale == 'ur') {
    HandyGoWorkerApp.localeNotifier.value = const Locale('ur');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI overlay style is handled by the theme

  // Set global error widget handler once, before runApp
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const HandyGoWorkerApp());
}

class HandyGoWorkerApp extends StatelessWidget {
  const HandyGoWorkerApp({super.key});

  /// Global locale notifier for language switching (English/Urdu)
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(
    const Locale('en'),
  );

  /// Global theme mode notifier for dark/light mode switching
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (_) => sl<AuthRepository>()),
        RepositoryProvider<WorkerRepository>(
          create: (_) => sl<WorkerRepository>(),
        ),
        RepositoryProvider<BookingRepository>(
          create: (_) => sl<BookingRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: sl<AuthRepository>(),
              workerRepository: sl<WorkerRepository>(),
            )..add(CheckAuthStatus()),
          ),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (_, __) {},
          child: ValueListenableBuilder<Locale>(
            valueListenable: HandyGoWorkerApp.localeNotifier,
            builder: (context, locale, _) {
              return ValueListenableBuilder<ThemeMode>(
                valueListenable: HandyGoWorkerApp.themeModeNotifier,
                builder: (context, themeMode, _) {
                  return MaterialApp(
                    navigatorKey: appNavigatorKey,
                    title: 'Handy Go - Worker',
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
                    supportedLocales: const [Locale('en'), Locale('ur')],
                    initialRoute: AppRoutes.splash,
                    onGenerateRoute: AppRoutes.generateRoute,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
