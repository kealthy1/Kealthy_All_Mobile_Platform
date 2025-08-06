import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[Background Message] Received: ${message.notification?.title}');

  await NotificationService.instance.setupFlutterNotifications();

  final imageUrl = message.notification?.android?.imageUrl ??
      message.notification?.apple?.imageUrl ??
      message.data['image'] ??
      "";

  await NotificationService.instance.showNotification(
    title: message.notification?.title ?? "No Title",
    body: message.notification?.body ?? "No Body",
    imageUrl: imageUrl,
  );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    print("[NotificationService] Initializing Firebase Messaging...");

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print(
        "[NotificationService] Notification permission status: ${settings.authorizationStatus}");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print(
          "[onMessage] 🔔 Received foreground notification: ${message.notification?.title}");
      await NotificationService.instance.addNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          "[onMessageOpenedApp] 📱 Opened from Background: ${message.notification?.title}");
      print("[onMessageOpenedApp] Full message data: ${message.data}");
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print(
            "[getInitialMessage] 🏁 Opened from Terminated State: ${message.notification?.title}");
        print("[getInitialMessage] Full message data: ${message.data}");
      }
    });

    final token = await _firebaseMessaging.getToken();
    print('[FCM Token] $token');
     if (token != null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("fcm_token", token); // ✅ Save FCM Token
    print("✅ [FCM Token Saved] in SharedPreferences: $token");
  }
  }

  Future<void> setupFlutterNotifications() async {
    if (_isInitialized) return;
  Int64List vibrationPattern = Int64List.fromList([0, 500, 1000, 500]);
    print("[NotificationService] Setting up Flutter Local Notifications...");

    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      showBadge: true,
      vibrationPattern: vibrationPattern,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: AndroidInitializationSettings('mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _localNotifications.initialize(initializationSettings);
    _isInitialized = true;
    print("[NotificationService] Local Notifications Initialized.");
  }

  Future<void> addNotification(RemoteMessage message) async {
    final imageUrl = message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        message.data['image'] ??
        "";

    await showNotification(
      title: message.notification?.title ?? "No Title",
      body: message.notification?.body ?? "No Body",
      imageUrl: imageUrl,
    );
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    print("[showNotification] Displaying: $title - $body");

    BigPictureStyleInformation? bigPictureStyle;
    ByteArrayAndroidBitmap? largeIcon;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        print("[showNotification] Downloading image from: $imageUrl");
        final imageBytes = await _downloadImage(imageUrl);
        largeIcon = ByteArrayAndroidBitmap(imageBytes);
        bigPictureStyle = BigPictureStyleInformation(
          ByteArrayAndroidBitmap(imageBytes),
          contentTitle: title,
          summaryText: body,
        );
      } catch (e) {
        print('[showNotification] Error loading image: $e');
      }
    }

    await _localNotifications.show(
      title.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: bigPictureStyle,
          largeIcon: largeIcon,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final codec = await ui.instantiateImageCodec(response.bodyBytes);
      final frame = await codec.getNextFrame();
      final byteData =
          await frame.image.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } else {
      throw Exception('Failed to download image from $url');
    }
  }
}
