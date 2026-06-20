import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../config/firebase_config.dart';
import '../models/app_notification.dart';
import 'api_service.dart';
import 'device_id_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!FirebaseConfig.enabled) return;
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _api = ApiService();
  final _localNotifications = FlutterLocalNotificationsPlugin();

  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _initialized = false;
  bool _initializing = false;
  bool _firstRefresh = true;
  Timer? _pollTimer;
  String? _deviceId;
  String? _fcmToken;

  List<AppNotification> get notifications =>
      _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => _unreadCount;
  String? get deviceId => _deviceId;

  /// Call after first frame — do not block [main].
  Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      _deviceId = await DeviceIdService.getDeviceId();
      await _setupLocalNotifications();
      await _setupFirebase();
      await _registerDevice();
      await refresh();

      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
      _initialized = true;
    } catch (e, stack) {
      debugPrint('NotificationService init error: $e\n$stack');
    } finally {
      _initializing = false;
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'bhandara_notifications',
        'Bhandara Notifications',
        description: 'Alerts when a new Bhandara is added',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _setupFirebase() async {
    if (!FirebaseConfig.enabled) {
      debugPrint('Firebase skipped (set FirebaseConfig.enabled = true after setup)');
      return;
    }

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      _fcmToken = await messaging.getToken();

      messaging.onTokenRefresh.listen((token) async {
        _fcmToken = token;
        await _registerDevice();
      });

      FirebaseMessaging.onMessage.listen(_showPushNotification);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => refresh());
    } catch (e) {
      debugPrint('Firebase not configured: $e');
    }
  }

  Future<void> _registerDevice() async {
    if (_deviceId == null) return;

    try {
      await _api.registerDeviceToken(
        deviceId: _deviceId!,
        fcmToken: _fcmToken,
        platform: Platform.isAndroid ? 'android' : 'ios',
      );
    } catch (e) {
      debugPrint('Device registration failed (backend may be offline): $e');
    }
  }

  Future<void> refresh() async {
    if (_deviceId == null) return;

    try {
      final previousUnread = _unreadCount;
      _notifications = await _api.fetchNotifications(_deviceId!, unreadOnly: true);
      _unreadCount = _notifications.length;

      if (!_firstRefresh && _unreadCount > previousUnread && _notifications.isNotEmpty) {
        final newest = _notifications.first;
        await _showLocalNotification(newest.title, newest.body);
      }

      _firstRefresh = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Notification refresh failed: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    if (_deviceId == null) return;
    try {
      await _api.markNotificationRead(notificationId, _deviceId!);
    } catch (e) {
      debugPrint('markAsRead failed: $e');
    }
    _notifications = _notifications.where((n) => n.id != notificationId).toList();
    _unreadCount = _notifications.length;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    if (_deviceId == null) return;
    try {
      await _api.markAllNotificationsRead(_deviceId!);
    } catch (e) {
      debugPrint('markAllAsRead failed: $e');
    }
    _notifications = [];
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> _showPushNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'New Bhandara Added';
    final body = message.notification?.body ?? 'A new Bhandara was added nearby';
    await _showLocalNotification(title, body);
    await refresh();
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'bhandara_notifications',
      'Bhandara Notifications',
      channelDescription: 'Alerts when a new Bhandara is added',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }

  void disposeService() {
    _pollTimer?.cancel();
  }
}
