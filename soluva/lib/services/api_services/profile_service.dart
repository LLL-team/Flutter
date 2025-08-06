import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs.getString('auth_token'));
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await getToken();
    if (token == null) {
      return null;
    }
    final response = await http.get(
      Uri.parse('$baseUrl/profile/myProfile'),
      headers: {"Accept": "application/json", "Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print(
        "Failed to get user profile: ${response.statusCode} - ${response.body}",
      );
      return null;
    }
  }

  // Editar perfil del usuario
  static Future<bool> editUserProfile({
    required String? name,
    required String? lastName,
    required String? descripcion,
  }) async {
    final token = await getToken();
    if (token == null) {
      return false;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/profile/edit'),
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
