import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs.getString('auth_token'));
    return prefs.getString('auth_token');
  }

 
  // Editar perfil del usuario
  static Future<bool> editUserProfile({
    required String? name,
    required String? lastName,
    required String? descripcion,
  }) async {
    final token = await _getToken();
    if (token == null) {
      return false;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/user/edit'),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "last_name": lastName,
        "descripcion": descripcion,
      }),
    );

    if (response.statusCode == 200) {
      return true; // Éxito
    } else {
      print(
        "Failed to edit user profile: ${response.statusCode} - ${response.body}",
      );
      return false;
    }
  }
}
