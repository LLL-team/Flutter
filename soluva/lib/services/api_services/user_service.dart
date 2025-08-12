import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // print(prefs.getString('auth_token'));
    return prefs.getString('auth_token');
  }

  //falta endpont
  static Future<void> uploadProfileImage(String imagePath) async {
    final token = await _getToken(); // Obtener el token si lo usás
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-profile-image'),
    );

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    request.headers['Authorization'] = 'Bearer $token';

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Error al subir la imagen');
    }
  }

  static Future getFoto(String uuid) async {
    // print("UUID: $uuid");
    final response = await http.get(Uri.parse('$baseUrl/img/$uuid'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['foto'];
    } else {
      throw Exception('Error al obtener la foto del usuario');
    }
  }
}
