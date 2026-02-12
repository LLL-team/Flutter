import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path/path.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkerService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  /// Obtiene el token de autenticación
  /// NOTA: Esta función solo debe ser usada internamente por WorkerService
  /// Para uso externo, usar ApiService.getToken()
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Envía una solicitud para convertirse en trabajador
  static Future<http.Response> enviarSolicitudTrabajador({
    required String nationalId,
    required Map<String, dynamic> trade,
    required String taskDescription,
    String? description,
    File? facePhoto,
    Uint8List? webImageBytes,
    File? certifications,
    Uint8List? webCertificationBytes,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/worker/new');

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

      // Foto de rostro
      if (facePhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'face_photo',
            facePhoto.path,
            filename: basename(facePhoto.path),
            contentType: _getMimeType(facePhoto.path),
          ),
        );
      } else if (webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'face_photo',
            webImageBytes,
            filename: 'face_photo.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      // Foto de certificación
      if (certifications != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'certifications',
            certifications.path,
            filename: basename(certifications.path),
            contentType: _getMimeType(certifications.path),
          ),
        );
      } else if (webCertificationBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'certifications',
            webCertificationBytes,
            filename: 'certifications.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    } catch (e) {
      throw Exception('Failed to submit application: $e');
    }
  }

  /// Detecta MIME type basado en extensión
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

  /// Obtiene el estado de la solicitud de trabajador
  static Future<Map<String, dynamic>> getStatus() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final url = Uri.parse('$baseUrl/worker/status');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load worker status: ${response.statusCode}');
    }
  }

  /// Obtiene trabajadores por categoría
  static Future<List<dynamic>> getWorkersByCategory(String category) async {
    final url = Uri.parse(
      '$baseUrl/workers?trade=${Uri.encodeComponent(category)}',
    );

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception('Error al obtener trabajadores: ${response.statusCode}');
    }
  }

  /// Obtiene información de un trabajador por UUID
  static Future<Map<String, dynamic>> getWorkerByUuid(String id) async {
    final url = Uri.parse('$baseUrl/workers/$id');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al obtener trabajador: ${response.statusCode}');
    }
  }

  /// Agrega un servicio al perfil del trabajador
  static Future<Map<String, dynamic>> addWorkerService({
    required String type,
    required String category,
    required String service,
    required double cost,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final url = Uri.parse('$baseUrl/workerServices/add');

    // Convertir tipo al formato que espera la API
    String apiType = type;
    if (type == "hora") {
      apiType = "hour";
    } else if (type == "fijo") {
      apiType = "fixed";
    }

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'type': apiType,
        'category': category,
        'service': service,
        'cost': cost,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al agregar servicio: ${response.statusCode}');
    }
  }

  /// Obtiene los servicios de un trabajador
  static Future<List<Map<String, dynamic>>> getWorkerServices(
    String uuid,
  ) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final url = Uri.parse('$baseUrl/workerServices/get?uuid=$uuid');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw Exception('Error al obtener servicios: ${response.statusCode}');
    }
  }

  /// Actualiza el precio de un servicio del trabajador
  static Future<bool> updateWorkerServiceCost({
    required String service,
    required String category,
    required double cost,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final url = Uri.parse('$baseUrl/workerServices/update');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service': service,
        'category': category,
        'cost': cost,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      // Mostrar el error del servidor para depuración
      print('ERROR del servidor (${response.statusCode}): ${response.body}');
      throw Exception('Error ${response.statusCode}: ${response.body}');
    }
  }

  /// Crea o actualiza horarios del trabajador
  static Future<bool> updateWorkerSchedule({
    required List<Map<String, String>> schedule,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final url = Uri.parse('$baseUrl/schedule/new');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'schedule': schedule,
      }),
    );

    return response.statusCode == 201;
  }

  /// Obtiene los horarios de un trabajador
  static Future<List<Map<String, dynamic>>> getWorkerSchedule(
    String uuid,
  ) async {
    final url = Uri.parse('$baseUrl/schedule?uuid=$uuid');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> schedules = data['schedules'] ?? [];
      return schedules.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      return [];
    }
  }
}
