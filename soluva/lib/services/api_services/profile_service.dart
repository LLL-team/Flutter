import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ProfileService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs.getString('auth_token'));
    return prefs.getString('auth_token');
  }
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
      print(
        "Failed to get user profile: ${response.statusCode} - ${response.body}",
      );
      return null;
    }
  }

}
