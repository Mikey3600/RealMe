import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Top-level function for handling background messages.
///
/// Must be outside any class to be an isolated entry point.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If we need Firebase services in background, initializing is required.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

/// Service responsible for managing Push Notifications via FCM.
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initializes notification settings and listeners.
  Future<void> init() async {
    // 1. Request Permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not accepted permission');
      // TODO: Handle "permanently denied" state by guiding user to App Settings.
      return;
    }

    // 2. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // Here we could show a local notification or update UI state
      }
    });

    // 4. Get Token (for debugging or sending to backend)
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
    // TODO: Sync this token to backend/Firestore to target this specific device.
    // TODO: Listen to onTokenRefresh to update backend when token changes.
  }

  /// Sets up behaviors for when a user taps a notification.
  Future<void> setupInteractedMessage() async {
    // 1. App opened from terminated state
    try {
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }
    } catch (e) {
      debugPrint('Failed to get initial message: $e');
    }

    // 2. App opened from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    // Navigate to chat screen or handle deep link here
    // e.g. Navigator.pushNamed(context, '/chat', arguments: message.data['chatId']);
  }
}
