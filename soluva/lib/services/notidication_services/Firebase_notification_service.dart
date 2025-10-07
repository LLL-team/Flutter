import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class FirebaseService {
  static bool _initialized = false;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!kIsWeb) {
      print(" Este servicio solo se usa en Web.");
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
        ),
      );

      // 🔹 Pide permisos de notificación al navegador
      final permission = await html.Notification.requestPermission();
      if (permission != "granted") {
        print(" Permiso de notificaciones denegado");
        return;
      }

      // 🔹 Obtiene token FCM
      final token = await _messaging.getToken(
        vapidKey:
            "BJWlRVGdM8rG3KnlGPcMbpPRi4WkYTzE3jpEo7FApWgrbvyHFdWQpk1EsivxHBIdq-2tKyqQHxnxPxCAjXWlm9E ", // lo obtenés desde Firebase Console
      );
      print("✅ Token FCM Web: $token");

      // 🔹 Escucha mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Notificación recibida:");
        print("Título: ${message.notification?.title}");
        print("Cuerpo: ${message.notification?.body}");

        // Mostrar notificación del navegador
        html.Notification(
          message.notification?.title ?? "Nuevo mensaje",
          body: message.notification?.body ?? "",
        );
      });

      _initialized = true;
      print(" Firebase Messaging Web inicializado correctamente");
    } catch (e) {
      //  print(" Error al inicializar Firebase Messaging: $e");
    }
  }
}
