import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  /// Obtiene el token de autenticación
  /// NOTA: Esta función solo debe ser usada internamente por ProfileService
  /// Para uso externo, usar ApiService.getToken()
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Obtiene el perfil del usuario actual
  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await _getToken();
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
      return null;
    }
  }

  /// Edita el perfil del usuario
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

    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/notification/getNotifications'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error obteniendo notificaciones');
    }

    final List<dynamic> decoded = json.decode(response.body);

    final List<Map<String, dynamic>> notis = decoded
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return notis;
  }
}
