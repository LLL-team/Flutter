import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:convert';

class UserService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  /// Obtiene el token de autenticación
  /// NOTA: Esta función solo debe ser usada internamente por UserService
  /// Para uso externo, usar ApiService.getToken()
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Sube una imagen de perfil
  static Future<void> uploadProfileImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

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

  /// Obtiene la foto de un usuario por UUID
  static Future<Uint8List?> getFoto(String uuid) async {
    final response = await http.get(Uri.parse('$baseUrl/img/$uuid'));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Error al obtener la foto del usuario');
    }
  }

  static Future<void> sendFCMTokenToServer(String token) async {
    final url = Uri.parse('$baseUrl/user/fcm-token');

    final sectoken = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/notification/updateFcmToken'),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer $sectoken",
      },
      body: jsonEncode({"token": token}),
    );

    if (response.statusCode == 200) {
      print('Token FCM enviado al servidor correctamente');
    } else {
      print('Error al enviar el token FCM: ${response.statusCode}');
    }
  }
}
