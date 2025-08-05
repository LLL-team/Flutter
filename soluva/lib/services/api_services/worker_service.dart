// import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart';

class WorkerService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';
  // static Future<String?> _getToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('auth_token');
  // }
  static Future<Map<String, dynamic>> enviarSolicitudTrabajador({
    required String nationalId,
    required String trade,
    required String taskDescription,
    String? description,
    File? facePhoto,
    File? certifications,
    required String token, // si necesitás autenticación con Bearer token
  }) async {
    print("Enviando solicitud de trabajador con los siguientes datos:");
    print("National ID: $nationalId");
    final uri = Uri.parse('$baseUrl/worker/new');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['national_id'] = nationalId
      ..fields['trade'] = trade
      ..fields['task_description'] = taskDescription;

    if (description != null) {
      request.fields['description'] = description;
    }

    if (facePhoto != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'face_photo',
          facePhoto.path,
          filename: basename(facePhoto.path),
        ),
      );
    }

    if (certifications != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'certifications',
          certifications.path,
          filename: basename(certifications.path),
        ),
      );
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 201) {
      return {"success": true, "message": "Solicitud enviada con éxito"};
    } else {
      return {"success": false, "message": responseBody};
    }
  }
}
