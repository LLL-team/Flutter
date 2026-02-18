import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../api_services/api_service.dart';

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
          apiKey: "AIzaSyBydFW3DPVO1E8YE3GziH2kWaA57y9ejC0",
          authDomain: "soluva-1abd4.firebaseapp.com",
          projectId: "soluva-1abd4",
          storageBucket: "soluva-1abd4.firebasestorage.app",
          messagingSenderId: "67676164290",
          appId: "1:67676164290:web:58d35ac987693810826b5b",
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
            "BL-nJ6djtl7Qlb_rreERRnfSeeG0_cXQYhDs4ttP20tOPN4JooUdgxmCdXV7LMy-AI81x8SwMPDoFE-0t1P4k3Y",
      );
      print("✅ Token FCM Web: $token");

      if (token != null) ApiService.sendFCMTokenToServer(token);
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
      print(" Error al inicializar Firebase Messaging: $e");
    }
  }
}
