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

  static Future<bool> verifyLinkedAccount() async {
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

    return decoded['vinculado'] == true;
  }

  static Future<String?> getMercadoPagoConnectUrl(String trabajadorId) async {
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

  static Future<Map<String, dynamic>> removeMercadoPagoLink() async {
    final token = await _getToken();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/mercadopago/removeLink'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      final decoded = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Cuenta desvinculada correctamente'};
      }

      return {
        'success': false,
        'has_pending_job': decoded['has_pending_job'] == true,
        'message': decoded['message'] ?? 'Error al desvincular',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }
}
