import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/constants/app_colors.dart';
import 'injection_container.dart';

void main() async {
  // Wrap entire app in error zone to catch all errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.surface,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Initialize dependency injection
      await initializeDependencies();

      // Set custom error widget for release mode
      if (kReleaseMode) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please restart the app. If the problem persists, contact support.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          SystemNavigator.pop();
                        },
                        child: const Text('Close App'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        };
      }

      // Handle Flutter framework errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (kDebugMode) {
          // In debug mode, print the error
          debugPrint('Flutter Error: ${details.exception}');
          debugPrint('Stack trace: ${details.stack}');
        }
      };

      runApp(const HandyGoApp());
    },
    (error, stackTrace) {
      // Handle errors that escape the Flutter framework
      if (kDebugMode) {
        debugPrint('Uncaught error: $error');
        debugPrint('Stack trace: $stackTrace');
      }
    },
  );
}
