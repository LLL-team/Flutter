import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class UserService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // print(prefs.getString('auth_token'));
    return prefs.getString('auth_token');
  }

  static Future<void> uploadProfileImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    final token = await _getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/img/updateIMG'),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'profile_photo',
        imageBytes,
        filename: fileName,
      ),
    );

    request.headers['Authorization'] = 'Bearer $token';

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Error al subir la imagen');
    }
  }

  static Future<Uint8List?> getFoto(String uuid) async {
    final response = await http.get(Uri.parse('$baseUrl/img/$uuid'));
    if (response.statusCode == 200) {
      return response.bodyBytes; // <- devuelve los bytes de la imagen
    } else {
      throw Exception('Error al obtener la foto del usuario');
    }
  }
}
