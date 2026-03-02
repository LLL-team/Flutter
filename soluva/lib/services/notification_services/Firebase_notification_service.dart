import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api_services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseService {
  static bool _initialized = false;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static Future<void> initialize() async {
    if (_initialized) return;

    if (!kIsWeb) {
      debugPrint(" Este servicio solo se usa en Web.");
      return;
    }

    try {
      // 🔹 Inicializa Firebase
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCF1JXi_z9kLbIOcthLSzZOeFab-lc5RN0",
          authDomain: "solluvanotifications.firebaseapp.com",
          projectId: "solluvanotifications",
          storageBucket: "solluvanotifications.firebasestorage.app",
          messagingSenderId: "296702582098",
          appId: "1:296702582098:web:0f3716684c19b577bcee8b",
          measurementId: "G-2E1GWYP8WP",
        ),
      );

      // 🔹 Pide permisos de notificación al navegador
      final permission = await html.Notification.requestPermission();

      if (permission != "granted") {
        debugPrint(" Permiso de notificaciones denegado");
        return;
      }

      // 🔹 Obtiene token FCM
      final token = await _messaging.getToken(
        vapidKey: dotenv.env['ENV_VAPID'],
      );
      debugPrint("✅ Token FCM Web: $token");

      if (token != null) ApiService.sendFCMTokenToServer(token);
      // 🔹 Escucha mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint("Notificación recibida:");
        debugPrint("Título: ${message.notification?.title}");
        debugPrint("Cuerpo: ${message.notification?.body}");

        // Mostrar notificación del navegador
        html.Notification(
          message.notification?.title ?? "Nuevo mensaje",
          body: message.notification?.body ?? "",
        );
      });

      _initialized = true;
      debugPrint(" Firebase Messaging Web inicializado correctamente");
    } catch (e) {
      debugPrint(" Error al inicializar Firebase Messaging: $e");
    }
  }
}
