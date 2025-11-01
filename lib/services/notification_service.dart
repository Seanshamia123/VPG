import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Service to handle push notifications for messages
/// Supports both local notifications and Firebase Cloud Messaging
class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static FirebaseMessaging? _firebaseMessaging;
  static bool _initialized = false;
  
  // Notification channel for messages
  static const String _messageChannelId = 'message_channel';
  static const String _messageChannelName = 'Messages';
  static const String _messageChannelDescription = 'Notifications for new messages';

  /// Initialize notification service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    print('[NotificationService] Initializing...');
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Initialize Firebase (optional - for remote push)
    await _initializeFirebase();
    
    _initialized = true;
    print('[NotificationService] Initialized successfully');
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    // Android settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _messageChannelId,
      _messageChannelName,
      description: _messageChannelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Initialize Firebase Cloud Messaging (optional)
  static Future<void> _initializeFirebase() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;

      // Request permission for iOS
      await _requestPermission();

      // Get FCM token
      final token = await _firebaseMessaging?.getToken();
      print('[NotificationService] FCM Token: $token');
      
      // You can send this token to your backend to enable remote push
      // await _sendTokenToBackend(token);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
      
    } catch (e) {
      print('[NotificationService] Firebase initialization failed: $e');
      print('[NotificationService] Continuing with local notifications only');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging?.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('[NotificationService] Permission status: ${settings?.authorizationStatus}');
  }

  /// Show local notification for new message
  static Future<void> showMessageNotification({
    required int conversationId,
    required String senderName,
    required String messageContent,
    String? senderAvatar,
  }) async {
    print('[NotificationService] Showing notification for message from $senderName');

    // Format message preview (max 100 chars)
    final preview = messageContent.length > 100
        ? '${messageContent.substring(0, 100)}...'
        : messageContent;

    // Android notification details
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _messageChannelId,
      _messageChannelName,
      channelDescription: _messageChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        preview,
        contentTitle: senderName,
        summaryText: 'New message',
      ),
      // Group notifications by conversation
      groupKey: 'conversation_$conversationId',
    );

    // iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show notification
    await _localNotifications.show(
      conversationId, // Use conversation ID as notification ID
      senderName,
      preview,
      details,
      payload: 'conversation:$conversationId',
    );
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    print('[NotificationService] Notification tapped: $payload');

    if (payload != null && payload.startsWith('conversation:')) {
      final conversationId = int.tryParse(payload.split(':')[1]);
      if (conversationId != null) {
        // Navigate to chat screen
        _navigateToChat(conversationId);
      }
    }
  }

  /// Handle foreground Firebase message
  static void _handleForegroundMessage(RemoteMessage message) {
    print('[NotificationService] Foreground message: ${message.data}');

    final data = message.data;
    final conversationId = int.tryParse(data['conversation_id']?.toString() ?? '');
    final senderName = data['sender_name']?.toString() ?? 'Someone';
    final messageContent = data['message']?.toString() ?? 'New message';

    if (conversationId != null) {
      showMessageNotification(
        conversationId: conversationId,
        senderName: senderName,
        messageContent: messageContent,
      );
    }
  }

  /// Handle background Firebase message
  static void _handleBackgroundMessage(RemoteMessage message) {
    print('[NotificationService] Background message opened: ${message.data}');

    final data = message.data;
    final conversationId = int.tryParse(data['conversation_id']?.toString() ?? '');

    if (conversationId != null) {
      _navigateToChat(conversationId);
    }
  }

  /// Navigate to chat screen
  static void _navigateToChat(int conversationId) {
    // This will be implemented with your navigation logic
    // For now, we'll use a global navigator key
    print('[NotificationService] Navigate to conversation: $conversationId');
    
    // Example using named routes:
    // navigatorKey.currentState?.pushNamed(
    //   '/chat',
    //   arguments: {'conversationId': conversationId},
    // );
  }

  /// Cancel notification for a conversation
  static Future<void> cancelNotification(int conversationId) async {
    await _localNotifications.cancel(conversationId);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get notification badge count
  static Future<int> getBadgeCount() async {
    // Implement badge count logic based on unread messages
    return 0;
  }

  /// Update notification badge
  static Future<void> updateBadge(int count) async {
    // iOS badge update
    if (_firebaseMessaging != null) {
      // await _firebaseMessaging?.setAutoInitEnabled(true);
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[NotificationService] Background message received: ${message.messageId}');
  // Handle background message
}