import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

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
      }
      return data;
    } else {
      // print("Register failed: ${response.statusCode} - ${response.body}");
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

  
}
