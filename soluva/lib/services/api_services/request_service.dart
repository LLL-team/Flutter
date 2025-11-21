import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RequestService {
  static String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  static Future<List<Map<String, dynamic>>> getMyRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$baseUrl/request/myRequest'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      final list = decoded is Map && decoded['data'] is List
          ? decoded['data']
          : decoded;

      final List rawList = list is List ? list : [];

      return rawList.map<Map<String, dynamic>>((item) {
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
    }

    return [];
  }
}
