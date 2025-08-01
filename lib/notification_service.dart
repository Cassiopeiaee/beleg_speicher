// lib/services/notification_service.dart

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background-Handler muss ganz oben stehen (Entry-Point für iOS/Android)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Lokalen Notifications-Plugin neu initialisieren
  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  final iosSettings     = DarwinInitializationSettings();
  final initSettings    = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await notificationsPlugin.initialize(initSettings);

  // Zeige die eingehende Nachricht als lokale Notification
  final notif = message.notification;
  if (notif != null) {
    final androidDetails = AndroidNotificationDetails(
      'tax_deadline_channel',
      'Steuerfrist Erinnerungen',
      channelDescription: 'Erinnerungen an Deine Steuerfrist',
      importance: Importance.high,
      priority: Priority.high,
    );
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await notificationsPlugin.show(
      notif.hashCode,
      notif.title,
      notif.body,
      platformDetails,
    );
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// Muss vor runApp() aufgerufen werden
  Future<void> init() async {
    await _requestPermissions();
    await _initLocalNotifications();
    await _initFirebaseMessaging();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _initLocalNotifications() async {
    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit     = DarwinInitializationSettings();
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _localNotifications.initialize(initSettings);
  }

  Future<void> _initFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // Topic für Steuerfrist-Reminders
    await messaging.subscribeToTopic('tax_deadline');

    // Background-Handler registrieren
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground-Handler
    FirebaseMessaging.onMessage.listen((message) {
      _showNotification(message);
    });

    // Wenn App aus beendetem Zustand geöffnet wird
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _showNotification(initialMessage);
    }

    // Wenn App aus Hintergrund per Notification geöffnet wird
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _showNotification(message);
    });
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    final androidDetails = AndroidNotificationDetails(
      'tax_deadline_channel',
      'Steuerfrist Erinnerungen',
      channelDescription: 'Erinnerungen an Deine Steuerfrist',
      importance: Importance.high,
      priority: Priority.high,
    );
    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notif.hashCode,
      notif.title,
      notif.body,
      platformDetails,
    );
  }
}
