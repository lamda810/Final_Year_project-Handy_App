import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import '../constants/api_endpoints.dart';
import '../network/dio_client.dart';

/// Top-level background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Manages FCM push notifications end-to-end:
/// - Firebase initialization
/// - Permission request
/// - Token retrieval & registration with the backend
/// - Foreground/background/terminated message handling
/// - Local notification display
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  bool _firebaseReady = false;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Callback when user taps a notification
  void Function(Map<String, dynamic> data)? onNotificationTapped;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize Firebase and push notifications.
  /// Call this in main() after WidgetsFlutterBinding.ensureInitialized().
  Future<void> initialize() async {
    try {
      // 1. Initialize Firebase
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      _firebaseReady = true;
      debugPrint('[FCM] Firebase initialized');
    } catch (e) {
      debugPrint('[FCM] Firebase init failed: $e');
      _firebaseReady = false;
      return; // Can't proceed without Firebase
    }

    try {
      // 2. Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Initialize local notifications (for foreground display)
      await _initLocalNotifications();

      // 4. Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 5. Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 6. Check if app was opened from a terminated state notification
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // 7. Set foreground notification presentation options (iOS)
      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[FCM] Push notification service initialized');
    } catch (e) {
      debugPrint('[FCM] Push notification setup error: $e');
    }
  }

  // ============================================================
  // PERMISSIONS
  // ============================================================

  /// Request notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    if (!_firebaseReady || _messaging == null) {
      return false;
    }

    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('[FCM] Permission ${granted ? "granted" : "denied"}');
    return granted;
  }

  // ============================================================
  // TOKEN MANAGEMENT
  // ============================================================

  /// Get FCM token and register it with the backend notification service.
  /// Call this after the user is authenticated.
  Future<String?> getAndRegisterToken() async {
    try {
      if (!_firebaseReady || _messaging == null) {
        return null;
      }

      _fcmToken = await _messaging!.getToken();

      if (_fcmToken != null) {
        debugPrint('[FCM] Token: ${_fcmToken!.substring(0, 20)}...');
        await _registerTokenWithBackend(_fcmToken!);
      }

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _registerTokenWithBackend(newToken);
        debugPrint('[FCM] Token refreshed');
      });

      return _fcmToken;
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
      return null;
    }
  }

  /// Register the FCM device token with the backend so the notification
  /// service can deliver push notifications to this device.
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final dio = GetIt.instance<DioClient>().dio;
      await dio.post(
        ApiEndpoints.registerDevice,
        data: {
          'deviceToken': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
      debugPrint('[FCM] Token registered with backend');
    } catch (e) {
      debugPrint('[FCM] Error registering token: $e');
    }
  }

  /// Unregister token (call on logout)
  Future<void> unregisterToken() async {
    try {
      if (!_firebaseReady || _messaging == null) {
        _fcmToken = null;
        return;
      }

      final token = _fcmToken;
      await _messaging!.deleteToken();
      _fcmToken = null;

      if (token != null) {
        try {
          final dio = GetIt.instance<DioClient>().dio;
          await dio.delete(
            ApiEndpoints.unregisterDevice,
            data: {'deviceToken': token},
          );
        } catch (_) {}
      }

      debugPrint('[FCM] Token unregistered');
    } catch (e) {
      debugPrint('[FCM] Error unregistering token: $e');
    }
  }

  // ============================================================
  // LOCAL NOTIFICATIONS
  // ============================================================

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap from local notification
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            onNotificationTapped?.call(data);
          } catch (_) {}
        }
      },
    );

    // Create the notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'handy_go_notifications',
      'Handy Go Notifications',
      description: 'Notifications for bookings, updates, and alerts',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  /// Show a local notification (used for foreground messages)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'handy_go_notifications',
      'Handy Go Notifications',
      channelDescription: 'Notifications for bookings, updates, and alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // ============================================================
  // MESSAGE HANDLERS
  // ============================================================

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    onNotificationTapped?.call(message.data);
  }
}
