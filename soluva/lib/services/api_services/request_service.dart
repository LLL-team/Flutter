import 'dart:convert';
import 'package:flutter/foundation.dart';
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

    debugPrint('DEBUG changeStatus - UUID: $uuid');
    debugPrint('DEBUG changeStatus - Status: $status');
    debugPrint('DEBUG changeStatus - URL: $baseUrl/request/changeStatus');

    try {
      final body = jsonEncode({'uuid': uuid, 'status': status});
      debugPrint('DEBUG changeStatus - Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/request/changeStatus'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('DEBUG changeStatus - Response status: ${response.statusCode}');
      debugPrint('DEBUG changeStatus - Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "message": decoded['message'] ?? "Estado cambiado correctamente",
        };
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
      debugPrint('DEBUG changeStatus - Error: $e');
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  /// Obtiene una solicitud por su UUID
  static Future<Map<String, dynamic>?> getRequestById(String uuid) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/request/$uuid'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final item = jsonDecode(response.body);

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
      }
      return null;
    } catch (e) {
      debugPrint('Error getting request by ID: $e');
      return null;
    }
  }

  /// Crea una calificación para una solicitud
  static Future<Map<String, dynamic>> createRating({
    required String requestUuid,
    required int workQuality,
    required int punctuality,
    required int friendliness,
    String? review,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"success": false, "message": "No autenticado"};

    debugPrint('DEBUG createRating - Request UUID: $requestUuid');
    debugPrint(
      'DEBUG createRating - Ratings: work_quality=$workQuality, punctuality=$punctuality, friendliness=$friendliness',
    );

    try {
      final body = jsonEncode({
        'request': requestUuid,
        'work_quality': workQuality,
        'punctuality': punctuality,
        'friendliness': friendliness,
        if (review != null && review.isNotEmpty) 'review': review,
      });
      debugPrint('DEBUG createRating - Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/ratings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      debugPrint('DEBUG createRating - Response status: ${response.statusCode}');
      debugPrint('DEBUG createRating - Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          "success": true,
          "message": "Calificación enviada correctamente",
        };
      } else {
        final decoded = jsonDecode(response.body);
        var message = "Error al enviar la calificación";
        if (decoded['message'] != null) {
          if (decoded['message'] is String) {
            message = decoded['message'];
          } else if (decoded['error'] != null) {
            message = decoded['error'].toString();
          }
        }
        return {"success": false, "message": message};
      }
    } catch (e) {
      debugPrint('DEBUG createRating - Error: $e');
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  /// Crea una nueva solicitud de servicio
  static Future<Map<String, dynamic>> createRequest({
    required String location,
    required String date,
    required String type,
    required String subtype,
    required String workerUuid,
    required String startAt,
    required num amount,
    String? description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"success": false, "message": "No autenticado"};

    try {
      final bodyMap = <String, dynamic>{
        'location': location,
        'date': date,
        'type': type,
        'subtype': subtype,
        'uuid': workerUuid,
        'start_at': startAt,
        'ammount': amount,
      };

      if (description != null && description.isNotEmpty) {
        bodyMap['descripcion'] = description;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/request/new'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(bodyMap),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "message": "Solicitud enviada correctamente"};
      } else {
        final decoded = jsonDecode(response.body);
        String message = 'Error al enviar la solicitud';
        if (decoded['errors'] != null) {
          final errors = decoded['errors'] as Map<String, dynamic>;
          message = errors.values.first[0].toString();
        } else if (decoded['message'] != null) {
          message = decoded['message'].toString();
        }
        return {"success": false, "message": message};
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }

  static Future<Map<String, dynamic>> payment(
    String requestUuid,
    String cardToken,
    String paymentMethodId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return {"success": false, "message": "No autenticado"};

    try {
      final body = jsonEncode({
        'request_uuid': requestUuid,
        'metodo_de_pago': "mercadopago", //temp
        'token': cardToken,
        'payment_method_id': paymentMethodId,
      });

      final response = await http.post(
        Uri.parse('$baseUrl/transaction/mercadopago'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        return {"success": true, "message": "Pago realizado correctamente"};
      } else {
        final decoded = jsonDecode(response.body);
        var message = "Error al procesar el pago";
        if (decoded['message'] != null) {
          if (decoded['message'] is String) {
            message = decoded['message'];
          } else if (decoded['error'] != null) {
            message = decoded['error'].toString();
          }
        }
        return {"success": false, "message": message};
      }
    } catch (e) {
      debugPrint('DEBUG payment - Error: $e');
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }
}
