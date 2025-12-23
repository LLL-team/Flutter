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
}
