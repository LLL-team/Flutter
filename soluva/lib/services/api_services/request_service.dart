import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<Map<String, dynamic>> getMyRequests({int page = 1}) async {
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

        return {
          "worker_name": workerName,
          "service": item["type"],
          "created_at": item["date"],
          "scheduled_date": item["date"],
          "status": item["status"],
          "cost": item["amount"],
          "rejected": false,
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
}
