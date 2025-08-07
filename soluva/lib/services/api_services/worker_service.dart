import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';


class WorkerService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

static Future<Map<String, dynamic>> enviarSolicitudTrabajador({
  required String nationalId,
  required String trade,
  required String taskDescription,
  String? description,
  File? facePhoto,
  Uint8List? webImageBytes, // nuevo parámetro
  File? certifications,
  required String token,
}) async {
  final uri = Uri.parse('$baseUrl/worker/new');

  final request = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..headers['Accept'] = 'application/json'
    ..fields['national_id'] = nationalId
    ..fields['trade'] = trade
    ..fields['task_description'] = taskDescription;

  if (description != null) {
    request.fields['description'] = description;
  }

  if (facePhoto != null) {
    request.files.add(await http.MultipartFile.fromPath(
      'face_photo',
      facePhoto.path,
      filename: basename(facePhoto.path),
    ));
  } else if (webImageBytes != null) {
    request.files.add(http.MultipartFile.fromBytes(
      'face_photo',
      webImageBytes,
      filename: 'face_photo.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));
  }

  if (certifications != null) {
    request.files.add(await http.MultipartFile.fromPath(
      'certifications',
      certifications.path,
      filename: basename(certifications.path),
    ));
  }

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode == 201) {
    return {"success": true, "message": "Solicitud enviada con éxito"};
  } else {
    return {"success": false, "message": responseBody};
  }
}

  // Detecta MIME basado en extensión (para cert. en PDF o imagen)
  static MediaType _getMimeType(String path) {
    final ext = extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.webp':
        return MediaType('image', 'webp');
      case '.pdf':
        return MediaType('application', 'pdf');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
