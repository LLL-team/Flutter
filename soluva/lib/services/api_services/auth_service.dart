import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../notidication_services/Firebase_notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_service.dart';

class AuthService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

  static Future<void> initialize() async {
    final bool tokenValido = await ApiService.verifyToken();

    if (tokenValido) {
      handleAuthenticated();
    } else {
      await clearAuthData();
    }
  }

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['accessToken'];
      final name = data['name'];
      final lastName = data['last_name'];
      if (token != null) {
        await _saveToken(token);
        await _saveUserName(name, lastName);
      }
      return data;
    } else {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> register({
    required String name,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "last_name": lastName,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['accessToken'];

      if (token != null) {
        await _saveToken(token);
        // 🔽 Esto es lo que faltaba:
        await _saveUserName(name, lastName);
      }

      return data;
    } else {
      return null;
    }
  }

  /// Login con Google
  static Future<Map<String, dynamic>?> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Cerrar sesión previa de Google si existe
      await googleSignIn.signOut();

      // Iniciar sesión con Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // El usuario canceló el login
        return null;
      }

      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        return null;
      }

      // Enviar el token al backend
      final response = await http.post(
        Uri.parse("$baseUrl/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "token": idToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['accessToken'];
        final name = data['name'];
        final lastName = data['last_name'];

        if (token != null) {
          await _saveToken(token);
          await _saveUserName(name, lastName);
        }

        return data;
      } else {
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error en login con Google: $e');
      }
      return null;
    }
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> _saveUserName(String? name, String? lastName) async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = ((name ?? '') + ' ' + (lastName ?? '')).trim();
    await prefs.setString('user_name', fullName);
  }

  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final response = await http.post(
      Uri.parse("$baseUrl/auth/logout"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      await prefs.remove('auth_token');
    } else {
      // print("Logout failed: ${response.statusCode} - ${response.body}");
    }
  }

  static Future<bool> verifyToken() async {
    final token = await ApiService.getToken();
    if (token == null) return false;

    final response = await http.get(
      Uri.parse("$baseUrl/auth/verifyToken"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    return response.statusCode == 200;
  }

  static Future<void> handleAuthenticated() async {
    //final controller = NotificationController();
    //controller.init();
    //isLoggedIn.value = true;
    await FirebaseService.initialize();
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
  }
}
