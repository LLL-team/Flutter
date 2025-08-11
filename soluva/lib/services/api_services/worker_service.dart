import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:soluva/services/api_services/utils_service.dart';

class WorkerService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<Map<String, dynamic>> enviarSolicitudTrabajador({
    required String nationalId,
    required Map<String, List<String>> trade,
    required String taskDescription,
    String? description,
    File? facePhoto,
    Uint8List? webImageBytes,
    File? certifications,
    Uint8List? webCertificationBytes, // ← nuevo parámetro
    required String token,
  }) async {
    final url = Uri.parse('${UtilsService.baseUrl}/worker/new');
    try {
      var request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['national_id'] = nationalId;
      request.fields['trade'] = jsonEncode(trade);
      request.fields['task_description'] = taskDescription;
      if (description != null) {
        request.fields['description'] = description;
      }
      if (facePhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'face_photo',
          facePhoto.path,
          filename: basename(facePhoto.path),
          contentType: _getMimeType(facePhoto.path),
        ));
      } else if (webImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'face_photo',
          webImageBytes,
          filename: 'face_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }
      // Adjunta la foto de certificación si existe
      if (certifications != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'certifications',
          certifications.path,
          filename: basename(certifications.path),
          contentType: _getMimeType(certifications.path),
        ));
      } else if (webCertificationBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'certifications',
          webCertificationBytes,
          filename: 'certifications.jpg',
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        print(responseData);
        throw Exception('Failed to submit application: ${response.statusCode}');
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to submit application: $e');
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
