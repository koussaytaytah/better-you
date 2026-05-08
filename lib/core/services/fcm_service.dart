import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import '../utils/logger.dart';

// Top-level handler for background messages (required by FCM)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.i('FCM background message: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    AppLogger.i('FCM permission: ${settings.authorizationStatus}');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        AppLogger.i('FCM token refreshed for user $userId');
      });

      AppLogger.i('FCM token saved for user $userId');
    } catch (e) {
      AppLogger.e('Failed to save FCM token', e);
    }
  }

  Future<void> removeTokenForUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
      await _messaging.deleteToken();
      AppLogger.i('FCM token removed for user $userId');
    } catch (e) {
      AppLogger.e('Failed to remove FCM token', e);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.i('FCM foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Show local notification for foreground messages
    final notificationService = NotificationService();
    await notificationService.showCustomNotification(
      id: message.hashCode,
      title: notification.title ?? 'Better You',
      body: notification.body ?? '',
      channelId: message.data['type'] ?? 'general',
      channelName: _getChannelName(message.data['type']),
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    AppLogger.i('Notification tapped: ${message.data}');
    // Navigation is handled by the router based on data payload
  }

  String _getChannelName(String? type) {
    switch (type) {
      case 'chat':
        return 'Chat Messages';
      case 'friend_request':
        return 'Friend Requests';
      case 'badge':
        return 'Achievements';
      case 'streak':
        return 'Streak Reminders';
      default:
        return 'General Notifications';
    }
  }

  // Send a notification to a specific user.
  //
  // 1. Always writes to /notifications so the in-app bell icon updates instantly
  //    (works without Cloud Functions — Spark plan compatible).
  // 2. Also writes to /fcm_queue so the optional onFcmQueueCreate Cloud Function
  //    can dispatch a real FCM push when the app is closed (requires Blaze).
  Future<void> sendNotificationToUser({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. In-app notification (bell icon)
      await _firestore.collection('notifications').add({
        'toUserId': toUserId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Queue for real FCM push (handled server-side if Blaze is enabled)
      await _firestore.collection('fcm_queue').add({
        'toUserId': toUserId,
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.e('Failed to send notification', e);
    }
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<bool> isPermissionGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // Subscribe to a topic (e.g., 'all_users', 'premium_users')
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    AppLogger.i('Subscribed to FCM topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    AppLogger.i('Unsubscribed from FCM topic: $topic');
  }
}
