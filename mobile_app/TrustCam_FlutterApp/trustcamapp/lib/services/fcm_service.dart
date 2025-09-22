import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Notifications autorisées");
    } else {
      print("⚠️ Notifications refusées");
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 Notification reçue: ${message.notification?.title}");
    });
  }
}
