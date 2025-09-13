import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

import 'config.dart';

// Top-level background handler as required by firebase_messaging.
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._internal();

  static final PushNotificationService instance = PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? _deviceToken;
  NotificationSettings? _notificationSettings;

  Future<void> initialize() async {
    await Firebase.initializeApp();

    await _initializeLocalNotifications();

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _notificationSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    _deviceToken = await _firebaseMessaging.getToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      await _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('Notification tapped with data: ${message.data}');
      }
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Used for important notifications.',
      importance: Importance.high,
    );
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final AndroidNotification? android = notification?.android;

    if (notification != null && (android != null || defaultTargetPlatform == TargetPlatform.iOS)) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
        payload: jsonEncode(message.data),
      );
    }
  }

  String? get deviceToken => _deviceToken;
  NotificationSettings? get settings => _notificationSettings;

  Future<String?> refreshAndGetToken() async {
    _deviceToken = await _firebaseMessaging.getToken();
    return _deviceToken;
  }

  Future<http.Response> sendPushViaBackend({
    required String backendBaseUrl,
    String? token,
    String title = 'Hello from Flutter',
    String body = 'This is a test push',
    Map<String, dynamic>? data,
    bool isTopic = false,
  }) async {
    final String target = token ?? _deviceToken ?? '';

    final Uri uri = Uri.parse(backendBaseUrl + senderEndpointPath);
    final Map<String, dynamic> payload = <String, dynamic>{
      'token': target,
      'title': title,
      'body': body,
      'data': data ?? <String, dynamic>{'source': 'flutter_app'},
      'isTopic': isTopic,
    };

    return http.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
  }
}

