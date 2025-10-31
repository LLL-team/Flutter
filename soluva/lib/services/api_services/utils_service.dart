import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class UtilsService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<Map<String, dynamic>> getServices() async {
    final url = Uri.parse('$baseUrl/service');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      
      // Retornar directamente la estructura completa de 3 niveles
      return data;
    } else {
      throw Exception('Error al obtener servicios: ${response.statusCode}');
    }
  }
}