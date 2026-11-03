import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../utils/logger.dart';
import '../../features/notification/data/repositories/device_repository.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  AppLogger.info(
    'FCM Background message received: id=${message.messageId}, data=${message.data}',
    tag: 'FCM',
  );
}

/// Manages Push Notifications via Firebase Cloud Messaging (FCM)
/// and heads-up local notifications via FlutterLocalNotificationsPlugin.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();
  factory PushNotificationService() => instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final _notificationClickCtrl =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNotificationClicked =>
      _notificationClickCtrl.stream;

  bool _initialized = false;
  bool _firebaseAvailable = false;
  String? _activeChatId;

  static const String channelId = 'slink_messages';
  static const String channelName = 'Messages';
  static const String channelDescription = 'Slink chat messages and updates';

  /// Let the service know which chat is currently open on screen,
  /// so we don't display a duplicate heads-up popup for that chat.
  void setActiveChat(String? chatId) {
    _activeChatId = chatId;
  }

  /// Initialize notifications system
  Future<void> init() async {
    if (_initialized) return;

    AppLogger.info('Initializing PushNotificationService...', tag: 'FCM');

    // 1. Initialize local notifications first (works on Android, iOS, Windows, Linux, Mac)
    await _initLocalNotifications();

    // 2. Initialize Firebase (if supported and configured)
    await _initFirebase();

    _initialized = true;
  }

  Future<void> _initLocalNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
        linux: linuxInit,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          AppLogger.info('Local notification tapped: ${response.payload}', tag: 'FCM');
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final data = jsonDecode(response.payload!) as Map<String, dynamic>;
              _notificationClickCtrl.add(data);
            } catch (_) {
              _notificationClickCtrl.add({'chatId': response.payload});
            }
          }
        },
      );

      // Create Android Notification Channel
      if (!kIsWeb && Platform.isAndroid) {
        const androidChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );

        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.createNotificationChannel(androidChannel);
          await androidPlugin.requestNotificationsPermission();
        }
      }

      AppLogger.info('Local notifications initialized successfully', tag: 'FCM');
    } catch (e, st) {
      AppLogger.error('Failed to initialize local notifications', tag: 'FCM', error: e, stackTrace: st);
    }
  }

  Future<void> _initFirebase() async {
    // Only attempt Firebase on supported platforms
    if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      AppLogger.info('Firebase push notifications not enabled for platform: ${Platform.operatingSystem}', tag: 'FCM');
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseAvailable = true;
      AppLogger.info('Firebase initialized successfully for FCM', tag: 'FCM');

      final messaging = FirebaseMessaging.instance;

      // Set background handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info('Notification permission status: ${settings.authorizationStatus}', tag: 'FCM');

      // Set presentation options for foreground messages on Apple platforms
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for foreground FCM messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        AppLogger.info('App opened from FCM notification: ${message.data}', tag: 'FCM');
        _notificationClickCtrl.add(message.data);
      });

      // Check if app was opened from terminated state via notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info('App launched from terminated state via FCM: ${initialMessage.data}', tag: 'FCM');
        _notificationClickCtrl.add(initialMessage.data);
      }
    } catch (e) {
      AppLogger.warning('Firebase initialization failed or google-services is missing. Push notifications will run in fallback mode: $e', tag: 'FCM');
      _firebaseAvailable = false;
    }
  }

  /// Called when an FCM message arrives while the app is in the foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    AppLogger.info('FCM Foreground message received: ${message.data}', tag: 'FCM');

    final data = message.data;
    final chatId = data['chatId']?.toString();

    // Do not show banner if user is currently viewing this active chat
    if (chatId != null && chatId == _activeChatId) {
      AppLogger.debug('User is currently viewing chat $chatId, skipping heads-up notification', tag: 'FCM');
      return;
    }

    final title = message.notification?.title ??
        (data['senderUsername'] != null
            ? 'New message from ${data['senderUsername']}'
            : 'New message');
    final body = message.notification?.body ?? data['content']?.toString() ?? '';

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: data,
    );
  }

  /// Displays an immediate local notification (used for FCM foreground or WebSocket fallback)
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      final darwinDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      final payloadStr = payload != null ? jsonEncode(payload) : null;

      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payloadStr,
      );
    } catch (e, st) {
      AppLogger.error('Failed to display local notification', tag: 'FCM', error: e, stackTrace: st);
    }
  }

  /// Obtains the FCM token and registers it with the Slink backend
  Future<String?> registerWithBackend(DeviceRepository deviceRepo) async {
    if (!_firebaseAvailable) {
      AppLogger.debug('Firebase not available, skipping FCM token registration', tag: 'FCM');
      return null;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      // Listen for token updates
      messaging.onRegistered.listen((newToken) async {
        if (newToken.isNotEmpty) {
          AppLogger.info('FCM Token registered/refreshed: ${newToken.substring(0, newToken.length.clamp(0, 15))}...', tag: 'FCM');
          await SecureStorage().saveFcmToken(newToken);
          await deviceRepo.registerDevice(newToken);
        }
      });

      // Trigger token registration
      await messaging.register();
    } catch (e, st) {
      AppLogger.error('Failed to register FCM with backend', tag: 'FCM', error: e, stackTrace: st);
    }
    return null;
  }

  /// Unregister device token with backend on user logout
  Future<void> unregisterFromBackend(DeviceRepository deviceRepo) async {
    final token = await SecureStorage().getFcmToken();
    if (token != null && token.isNotEmpty) {
      await deviceRepo.unregisterDevice(token);
      await SecureStorage().deleteFcmToken();
    }
  }

  void dispose() {
    _notificationClickCtrl.close();
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService.instance;
});
