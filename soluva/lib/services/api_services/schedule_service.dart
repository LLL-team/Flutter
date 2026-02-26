import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  /// Obtiene los horarios de un trabajador por su UUID
  static Future<Map<String, dynamic>> getSchedules(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"success": false, "schedules": []};

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/schedule?uuid=$uuid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('DEBUG getSchedules - Response status: ${response.statusCode}');
      debugPrint('DEBUG getSchedules - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "schedules": decoded['schedules'] ?? [],
        };
      } else {
        return {"success": false, "schedules": []};
      }
    } catch (e) {
      debugPrint('DEBUG getSchedules - Error: $e');
      return {"success": false, "schedules": []};
    }
  }

  /// Reemplaza los horarios del trabajador autenticado por día
  /// schedulesByDay: Map con formato {"Monday": [{"start": "10:00", "end": "12:00"}], ...}
  static Future<Map<String, dynamic>> replaceSchedules(
      Map<String, List<Map<String, String>>> schedulesByDay) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"success": false, "message": "No autenticado"};

    try {
      final body = jsonEncode(schedulesByDay);
      debugPrint('DEBUG replaceSchedules - Body: $body');

      final response = await http.put(
        Uri.parse('$baseUrl/schedule/replace'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('DEBUG replaceSchedules - Response status: ${response.statusCode}');
      debugPrint('DEBUG replaceSchedules - Response body: ${response.body}');

      if (response.statusCode == 200) {
        return {"success": true, "message": "Horarios actualizados correctamente"};
      } else {
        final decoded = jsonDecode(response.body);
        return {
          "success": false,
          "message": decoded['error'] ?? decoded['message'] ?? "Error al actualizar horarios"
        };
      }
    } catch (e) {
      debugPrint('DEBUG replaceSchedules - Error: $e');
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  /// Crea nuevos horarios para el trabajador autenticado
  static Future<Map<String, dynamic>> createSchedules(
      List<Map<String, String>> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"success": false, "message": "No autenticado"};

    try {
      final body = jsonEncode({"schedule": schedules});
      debugPrint('DEBUG createSchedules - Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/schedule/new'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('DEBUG createSchedules - Response status: ${response.statusCode}');
      debugPrint('DEBUG createSchedules - Response body: ${response.body}');

      if (response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "message": decoded['message'] ?? "Horarios creados correctamente"
        };
      } else {
        final decoded = jsonDecode(response.body);
        return {
          "success": false,
          "message": decoded['message'] ?? "Error al crear horarios"
        };
      }
    } catch (e) {
      debugPrint('DEBUG createSchedules - Error: $e');
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }
}
