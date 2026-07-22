import 'dart:convert';
import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../routing/app_pages.dart';

/// Must remain a top-level function (background isolate).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final idTail = message.messageId?.length != null && message.messageId!.length > 6
      ? message.messageId!.substring(message.messageId!.length - 6)
      : message.messageId;
  dev.log('[FCM] Background message id=…$idTail type=${message.data['type']}');
  // Do not navigate or use UI/BuildContext here.
}

String _tokenFingerprint(String? token) {
  if (token == null || token.isEmpty) return 'none';
  if (token.length <= 6) return '***';
  return '…${token.substring(token.length - 6)}';
}

/// Central FCM + local notification service (register once for app lifetime).
class NotificationService extends GetxService {
  late final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'stockpro_high_importance',
    'StockPro Notifications',
    description: 'Notifications for StockPro operations',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  final Set<String> _shownMessageIds = <String>{};
  Map<String, dynamic>? _pendingNavigation;
  bool _listenersAttached = false;
  Worker? _tokenRefreshWorker;

  Future<NotificationService> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _fcm = FirebaseMessaging.instance;
      dev.log('[FCM] Firebase initialized');

      await requestPermission();
      await _initLocalNotifications();
      _setupFCMListeners();
      await _attachTokenRefresh();

      final token = await getFCMToken();
      dev.log('[FCM] Token fingerprint=${_tokenFingerprint(token)}');
    } catch (e) {
      dev.log('[FCM] Initialization error: $e');
      try {
        await _initLocalNotifications();
      } catch (_) {}
    }
    return this;
  }

  Future<AuthorizationStatus> requestPermission() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();

      dev.log('[FCM] Permission status=${settings.authorizationStatus}');
      return settings.authorizationStatus;
    } catch (e) {
      dev.log('[FCM] Permission request failed: $e');
      return AuthorizationStatus.notDetermined;
    }
  }

  Future<String?> getFCMToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      dev.log('[FCM] getToken failed: $e');
      return null;
    }
  }

  /// Call after successful auth to sync token (and flush pending nav).
  Future<void> registerCurrentToken(
    Future<void> Function(String token) register,
  ) async {
    final token = await getFCMToken();
    if (token == null || token.isEmpty) {
      dev.log('[FCM] register skipped — empty token');
      return;
    }
    await register(token);
    dev.log('[FCM] Token registered fingerprint=${_tokenFingerprint(token)}');
    consumePendingNavigation();
  }

  Map<String, dynamic>? takePendingNavigation() {
    final pending = _pendingNavigation;
    _pendingNavigation = null;
    return pending;
  }

  void consumePendingNavigation() {
    final pending = takePendingNavigation();
    if (pending != null) {
      // Delay until navigator is ready.
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        navigateFromPayload(pending);
      });
    }
  }

  Future<void> handleInitialMessage() async {
    try {
      final initial = await _fcm.getInitialMessage();
      if (initial != null) {
        dev.log('[FCM] Initial (terminated) message type=${initial.data['type']}');
        _pendingNavigation = Map<String, dynamic>.from(initial.data);
      }
    } catch (e) {
      dev.log('[FCM] getInitialMessage failed: $e');
    }
  }

  Future<void> _attachTokenRefresh() async {
    _fcm.onTokenRefresh.listen((newToken) async {
      dev.log('[FCM] Token refreshed fingerprint=${_tokenFingerprint(newToken)}');
      // AuthController / callers should re-register when session exists.
      // Store for next registerCurrentToken invocation.
      try {
        if (Get.isRegistered<NotificationService>()) {
          // Signal via reactive update if needed later.
        }
      } catch (_) {}
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          Get.toNamed(Routes.notifications);
          return;
        }
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          navigateFromPayload(data);
        } catch (_) {
          Get.toNamed(Routes.notifications);
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void _setupFCMListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final idTail = message.messageId?.length != null &&
              message.messageId!.length > 6
          ? message.messageId!.substring(message.messageId!.length - 6)
          : message.messageId;
      dev.log('[FCM] Foreground message id=…$idTail');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      dev.log('[FCM] Opened from background type=${message.data['type']}');
      navigateFromPayload(Map<String, dynamic>.from(message.data));
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final dedupeKey = message.messageId ??
        '${notification.title}|${notification.body}|${message.sentTime?.millisecondsSinceEpoch}';
    if (_shownMessageIds.contains(dedupeKey)) return;
    _shownMessageIds.add(dedupeKey);
    if (_shownMessageIds.length > 100) {
      _shownMessageIds.remove(_shownMessageIds.first);
    }

    final payload = jsonEncode(message.data);

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'StockPro',
      body: notification.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@drawable/ic_notification',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          channelShowBadge: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Safe navigation from FCM / local notification data.
  void navigateFromPayload(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
    final entityId = (data['entityId'] ?? data['requestId'] ?? '').toString();
    final route = (data['route'] ?? '').toString();

    // Allowlist only — never trust arbitrary routes blindly.
    switch (type) {
      case 'warehouse_transfer':
      case 'inventory_transfer':
        Get.toNamed(Routes.receivedDevices);
        return;
      case 'custody_request':
      case 'device_assignment':
        Get.toNamed(Routes.serializedCustody);
        return;
      case 'courier_request':
        if (entityId.isNotEmpty) {
          Get.toNamed(
            Routes.courierRequestDetails,
            arguments: {'id': entityId},
          );
        } else {
          Get.toNamed(Routes.courierRequests);
        }
        return;
      case 'device_installation':
        Get.toNamed(Routes.mySerializedInventory);
        return;
      case 'withdrawn_device':
      case 'device_withdrawal':
      case 'system_alert':
      case 'low_stock':
      case 'custom':
        Get.toNamed(Routes.notifications);
        return;
    }

    if (route == Routes.serializedCustody ||
        route == Routes.receivedDevices ||
        route == Routes.notifications ||
        route == Routes.courierRequests ||
        route == Routes.dashboard) {
      Get.toNamed(route);
      return;
    }

    if (route.startsWith('/custody/') || route.contains('serialized-custody')) {
      Get.toNamed(Routes.serializedCustody);
      return;
    }

    Get.toNamed(Routes.notifications);
  }

  @override
  void onClose() {
    _tokenRefreshWorker?.dispose();
    super.onClose();
  }
}
