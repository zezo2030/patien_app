import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  print('📱 Title: ${message.notification?.title}');
  print('📱 Body: ${message.notification?.body}');
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();
  
  bool _isInitialized = false;
  String? _currentToken;
  
  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ NotificationService already initialized');
      return;
    }
    
    try {
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Setup message handlers
      await _setupMessageHandlers();
      
      // Get and save initial token
      await _getAndSaveToken();
      
      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
      
      _isInitialized = true;
      print('✅ NotificationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
      rethrow;
    }
  }
  
  // Request notification permissions
  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requires POST_NOTIFICATIONS permission
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print('✅ Notification permission granted');
      } else {
        print('⚠️ Notification permission denied');
      }
    } else if (Platform.isIOS) {
      // Request iOS permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ iOS notification permission granted');
      } else {
        print('⚠️ iOS notification permission denied');
      }
    }
  }
  
  // Initialize local notifications for foreground notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'virclinc_notifications',
        'VirClinc Notifications',
        description: 'Notifications for appointments and messages',
        importance: Importance.high,
        playSound: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }
  
  // Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Foreground message received: ${message.messageId}');
      _showLocalNotification(message);
    });
    
    // Message opened app handler (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Message opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });
    
    // Check if app was opened from a notification
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App opened from notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }
  
  // Get device token and save to backend
  Future<String?> _getAndSaveToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        _currentToken = token;
        print('📱 Device token: ${token.substring(0, 20)}...');
        return token;
      }
      return null;
    } catch (e) {
      print('❌ Error getting device token: $e');
      return null;
    }
  }
  
  // Get current device token
  Future<String?> getDeviceToken() async {
    if (_currentToken != null) {
      return _currentToken;
    }
    return await _getAndSaveToken();
  }
  
  // Send token to backend
  // Note: authToken should be obtained from AuthService
  Future<void> sendTokenToBackend(String userId, String authToken) async {
    try {
      final deviceToken = await getDeviceToken();
      if (deviceToken == null) {
        print('⚠️ No device token available');
        return;
      }
      
      final platform = Platform.isAndroid ? 'android' : 'ios';
      await _apiService.saveDeviceToken(userId, deviceToken, platform, authToken);
      print('✅ Device token sent to backend');
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }
  
  // Delete token from backend
  // Note: authToken should be obtained from AuthService
  Future<void> deleteTokenFromBackend(String userId, String authToken) async {
    try {
      final deviceToken = await getDeviceToken();
      if (deviceToken == null) {
        return;
      }
      
      await _apiService.deleteDeviceToken(userId, deviceToken, authToken);
      print('✅ Device token deleted from backend');
    } catch (e) {
      print('❌ Error deleting token from backend: $e');
    }
  }
  
  // Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    print('🔄 Token refreshed: ${newToken.substring(0, 20)}...');
    _currentToken = newToken;
    // Token will be sent to backend on next login or when user is logged in
  }
  
  // Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    
    final androidDetails = AndroidNotificationDetails(
      'virclinc_notifications',
      'VirClinc Notifications',
      channelDescription: 'Notifications for appointments and messages',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }
  
  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('📱 Notification tapped: ${message.data}');
    // TODO: Navigate to appropriate screen based on notification type
    // This will be implemented when we add navigation handling
  }
  
  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Local notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on notification type
  }
  
  // Setup message handlers (public method for re-initialization if needed)
  Future<void> setupMessageHandlers() async {
    await _setupMessageHandlers();
  }
}

