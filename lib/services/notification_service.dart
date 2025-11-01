import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:escort/services/api_client.dart';
import 'package:escort/config/api_config.dart';
import 'package:flutter/material.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[NotificationService] Background message received: ${message.messageId}');
  print('[NotificationService] Title: ${message.notification?.title}');
  print('[NotificationService] Body: ${message.notification?.body}');
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static String? _fcmToken;
  static Function(Map<String, dynamic>)? _onMessageTapped;

  /// Initialize notification service
  static Future<void> initialize({
    Function(Map<String, dynamic>)? onMessageTapped,
  }) async {
    if (_initialized) return;
    
    _onMessageTapped = onMessageTapped;
    
    try {
      print('[NotificationService] Initializing...');
      
      // Request permissions (iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('[NotificationService] Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print('[NotificationService] Notification permissions denied');
        return;
      }
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      _fcmToken = await _fcm.getToken();
      print('[NotificationService] FCM Token: $_fcmToken');
      
      // Send token to backend
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }
      
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle message tap (app opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
      
      // Check if app was opened from a notification
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }
      
      // Listen for token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        print('[NotificationService] Token refreshed: $newToken');
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });
      
      _initialized = true;
      print('[NotificationService] Initialized successfully');
      
    } catch (e) {
      print('[NotificationService] Initialization error: $e');
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          try {
            final data = jsonDecode(details.payload!);
            _onMessageTapped?.call(data);
          } catch (e) {
            print('[NotificationService] Error parsing notification payload: $e');
          }
        }
      },
    );
    
    print('[NotificationService] Local notifications initialized');
  }

  /// Send FCM token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final url = '${ApiConfig.api}/users/fcm-token';
      await ApiClient.postJson(
        url,
        {'fcm_token': token},
        auth: true,
      );
      print('[NotificationService] Token sent to backend');
    } catch (e) {
      print('[NotificationService] Error sending token to backend: $e');
    }
  }

  /// Handle foreground messages (app is open)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('[NotificationService] Foreground message received');
    print('  Title: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Data: ${message.data}');
    
    // Show local notification even when app is in foreground
    await _showLocalNotification(message);
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    
    // Android notification details
    final androidDetails = AndroidNotificationDetails(
      'messages_channel', // Channel ID
      'Messages', // Channel name
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      // WhatsApp-style notification
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        htmlFormatBigText: true,
        contentTitle: notification.title,
        htmlFormatContentTitle: true,
      ),
      // Show notification icon
      icon: '@mipmap/ic_launcher',
      // Color for notification (optional)
      color: const Color(0xFF2196F3),
    );
    
    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Show notification
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
    
    print('[NotificationService] Local notification shown');
  }

  /// Handle notification tap (app opened from notification)
  static void _handleMessageTap(RemoteMessage message) {
    print('[NotificationService] Notification tapped');
    print('  Data: ${message.data}');
    
    if (_onMessageTapped != null) {
      _onMessageTapped!(message.data);
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Check if initialized
  static bool get isInitialized => _initialized;

  /// Request permissions again (if user denied)
  static Future<bool> requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Delete FCM token (for logout)
  static Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      _fcmToken = null;
      print('[NotificationService] Token deleted');
    } catch (e) {
      print('[NotificationService] Error deleting token: $e');
    }
  }

  /// Subscribe to topic (optional - for broadcast notifications)
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      print('[NotificationService] Subscribed to topic: $topic');
    } catch (e) {
      print('[NotificationService] Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      print('[NotificationService] Unsubscribed from topic: $topic');
    } catch (e) {
      print('[NotificationService] Error unsubscribing from topic: $e');
    }
  }

  /// Set badge count (iOS)
  static Future<void> setBadgeCount(int count) async {
    try {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      // Note: Badge count management depends on your backend
      print('[NotificationService] Badge count set: $count');
    } catch (e) {
      print('[NotificationService] Error setting badge count: $e');
    }
  }
}