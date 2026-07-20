import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_endpoints.dart';
import '../navigation/app_navigator.dart';
import '../../presentation/routes/app_routes.dart';

/// Centralized Dio client for the Worker app
class DioClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  // Guards against multiple concurrent 401s (e.g. several requests failing
  // around the same time) each trying to push the login route.
  bool _isRedirectingToLogin = false;

  DioClient({
    required this.dio,
    required this.secureStorage,
  }) {
    _configureDio();
  }

  void _configureDio() {
    dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      // Harmless when hitting localhost/LAN directly; needed when baseUrl
      // is an ngrok tunnel so its free-tier interstitial page never
      // intercepts a request that ends up looking browser-like.
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );

    // Interceptor for Auth (JWT injection)
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: 'access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // A 401 on an authenticated request means the stored session is no
          // longer valid (expired, or issued by an old backend). Clear it so
          // the app returns to login on next launch instead of being stuck
          // with a dead token.
          if (error.response?.statusCode == 401 &&
              error.requestOptions.headers.containsKey('Authorization')) {
            await secureStorage.delete(key: 'access_token');
            await secureStorage.delete(key: 'refresh_token');
            _redirectToLogin();
          }
          return handler.next(error);
        },
      ),
    );

    // Logger
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  void _redirectToLogin() {
    if (_isRedirectingToLogin) return;
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) return;

    _isRedirectingToLogin = true;
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    // Let a later session-expiry (after the user logs back in) trigger
    // another redirect instead of being silently ignored forever.
    Future.delayed(const Duration(seconds: 1), () {
      _isRedirectingToLogin = false;
    });
  }
}
