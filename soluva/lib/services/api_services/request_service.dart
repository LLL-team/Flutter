import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  /// Obtiene las solicitudes creadas por el usuario autenticado
  static Future<Map<String, dynamic>> getUserRequests({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"data": [], "last_page": 1, "current_page": 1};

    final response = await http.get(
      Uri.parse('$baseUrl/request/request?page=$page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final list = decoded['data'] is List ? decoded['data'] : [];
      final currentPage = decoded['current_page'] ?? page;
      final lastPage = decoded['last_page'] ?? page;

      final parsed = list.map<Map<String, dynamic>>((item) {
        final worker = item['worker']?['user'];
        final workerName = worker != null
            ? "${worker['name']} ${worker['last_name']}"
            : "Trabajador";

        final status = item["status"]?.toString().toLowerCase() ?? 'pending';

        return {
          "worker_name": workerName,
          "service": item["type"],
          "created_at": item["date"],
          "scheduled_date": item["date"],
          "status": status,
          "cost": item["amount"],
          "rejected": status == 'rejected',
          // Datos adicionales para los popups
          "id": item["uuid"] ?? item["id"],
          "uuid": item["uuid"],
          "user": item["user"],
          "worker": item["worker"],
          "category": item["category"],
          "date": item["date"],
          "time": item["time"],
          "location": item["location"],
          "address": item["address"],
          "amount": item["amount"],
          "type": item["type"],
        };
      }).toList();

      return {
        "data": parsed,
        "current_page": currentPage,
        "last_page": lastPage,
      };
    }

    return {"data": [], "last_page": 1, "current_page": 1};
  }

  /// Obtiene las solicitudes asignadas al trabajador autenticado
  static Future<Map<String, dynamic>> getWorkerRequests({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"data": [], "last_page": 1, "current_page": 1};

    final response = await http.get(
      Uri.parse('$baseUrl/request/myRequest?page=$page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final list = decoded['data'] is List ? decoded['data'] : [];
      final currentPage = decoded['current_page'] ?? page;
      final lastPage = decoded['last_page'] ?? page;

      final parsed = list.map<Map<String, dynamic>>((item) {
        final worker = item['worker']?['user'];
        final workerName = worker != null
            ? "${worker['name']} ${worker['last_name']}"
            : "Trabajador";

        final status = item["status"]?.toString().toLowerCase() ?? 'pending';

        return {
          "worker_name": workerName,
          "service": item["type"],
          "created_at": item["date"],
          "scheduled_date": item["date"],
          "status": status,
          "cost": item["amount"],
          "rejected": status == 'rejected',
          // Datos adicionales para los popups
          "id": item["uuid"] ?? item["id"],
          "uuid": item["uuid"],
          "user": item["user"],
          "worker": item["worker"],
          "category": item["category"],
          "date": item["date"],
          "time": item["time"],
          "location": item["location"],
          "address": item["address"],
          "amount": item["amount"],
          "type": item["type"],
        };
      }).toList();

      return {
        "data": parsed,
        "current_page": currentPage,
        "last_page": lastPage,
      };
    }

    return {"data": [], "last_page": 1, "current_page": 1};
  }

  /// Alias para mantener compatibilidad con código existente
  @Deprecated('Use getUserRequests or getWorkerRequests instead')
  static Future<Map<String, dynamic>> getMyRequests({int page = 1}) async {
    return getUserRequests(page: page);
  }

  /// Cambia el estado de una solicitud
  static Future<Map<String, dynamic>> changeStatus({
    required String uuid,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"success": false, "message": "No autenticado"};

    print('DEBUG changeStatus - UUID: $uuid');
    print('DEBUG changeStatus - Status: $status');
    print('DEBUG changeStatus - URL: $baseUrl/request/changeStatus');

    try {
      final body = jsonEncode({
        'uuid': uuid,
        'status': status,
      });
      print('DEBUG changeStatus - Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/request/changeStatus'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('DEBUG changeStatus - Response status: ${response.statusCode}');
      print('DEBUG changeStatus - Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {"success": true, "message": decoded['message'] ?? "Estado cambiado correctamente"};
      } else {
        final decoded = jsonDecode(response.body);
        var message = "Error al cambiar el estado";
        if (decoded['message'] != null) {
          if (decoded['message'] is String) {
            message = decoded['message'];
          } else {
            // If message is an Exception object or other type, extract meaningful info
            message = decoded['message'].toString();
          }
        }
        return {"success": false, "message": message};
      }
    } catch (e) {
      print('DEBUG changeStatus - Error: $e');
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }
}
