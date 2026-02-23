import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MercadoPagoService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, dynamic>?> verifyLinkedAccount() async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/mercadopago/verifyLinkedAccount'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error verifying MercadoPago link');
    }

    final Map<String, dynamic> decoded =
        json.decode(response.body) as Map<String, dynamic>;

    if (decoded['linked'] == true) {
      return decoded['account'] as Map<String, dynamic>;
    }

    return null;
  }

  static Future<String> getMercadoPagoConnectUrl(String trabajadorId) async {
    final token = await _getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/mercadopago/connect/$trabajadorId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error getting MercadoPago connect URL');
    }

    final Map<String, dynamic> decoded =
        json.decode(response.body) as Map<String, dynamic>;

    return decoded['url'];
  }

  static Future<void> removeMercadoPagoLink() async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/mercadopago/removeLink'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error removing MercadoPago link');
    }
  }
}
