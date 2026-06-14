import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Handler executado quando o app está fechado (precisa ser top-level)
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  // Firebase já persiste a notificação; nada a fazer aqui
}

class FcmService {
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _androidChannel = AndroidNotificationChannel(
    'gama_alta_prioridade',
    'GAMA — Notificações',
    importance: Importance.high,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;

    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    // Canal Android de alta prioridade
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    // Permissão iOS / Android 13+
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Notificações em foreground: mostrar banner via local notifications
    FirebaseMessaging.onMessage.listen(_onForeground);
  }

  static void _onForeground(RemoteMessage message) {
    final notif = message.notification;
    final android = message.notification?.android;
    if (notif == null || android == null) return;

    _localNotif.show(
      notif.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  static Future<String?> getToken() =>
      FirebaseMessaging.instance.getToken();

  static Future<void> deleteToken() =>
      FirebaseMessaging.instance.deleteToken();
}
