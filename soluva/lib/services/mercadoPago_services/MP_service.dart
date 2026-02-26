import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get baseUrl => dotenv.env['BASE_URL'] ?? '';
// const String baseUrl = "http://127.0.0.1:8000/api";
const String publicKey = "APP_USR-2e90a051-50d1-4bd7-836d-0d91834af576";

Future<void> crearTransaccion({
  required String solicitudId,
  required String metodoDePago,
  required double monto,
  required String cardToken,
  required String paymentMethodId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final response = await http.post(
    Uri.parse("$baseUrl/transacciones/nueva"),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': "Bearer $token",
    },
    body: jsonEncode({
      'solicitud': solicitudId,
      'metodo_de_pago': metodoDePago,
      'monto': monto,
      'token': cardToken,
      'payment_method_id': paymentMethodId,
    }),
  );

  if (response.statusCode != 201) {
    debugPrint('Error: ${response.body}');
  }
}

Future<String> generarCardToken({
  required String cardNumber,
  required String cardHolderName,
  required String cardExpirationMonth,
  required String cardExpirationYear,
  required String securityCode,
  required String identificationType,
  required String identificationNumber,
}) async {
  final url = Uri.parse(
    'https://api.mercadopago.com/v1/card_tokens?public_key=$publicKey',
  );

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "card_number": cardNumber,
      "expiration_month": int.parse(cardExpirationMonth),
      "expiration_year": int.parse(cardExpirationYear),
      "security_code": securityCode,
      "cardholder": {
        "name": cardHolderName,
        "identification": {
          "type": identificationType,
          "number": identificationNumber,
        },
      },
    }),
  );

  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);
    return data['id']; // Este es el card_token
  } else {
    throw Exception('Error al generar el card_token: ${response.body}');
  }
}

//se usa cuando tengamos la vinculacion con mercado pago, para verificar si el trabajador ya tiene una cuenta vinculada
Future<bool> checkVinculacionMP() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.get(
    Uri.parse("$baseUrl/mercadopago/verifyLinkedAccount"),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["vinculado"] == true;
  }
  return false;
}

Future<void> conectarMercadoPago(String trabajadorUuid) async {
  //todo cuando actualizemos el vincular
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.get(
    Uri.parse("$baseUrl/mercadopago/connect/$trabajadorUuid"),
    headers: {"Authorization": "Bearer $token"},
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final url = data["url"];
    if (url != null) {
      await launchUrl(Uri.parse(url));
    }
  } else {
    throw Exception("Error al obtener URL de conexión: ${response.body}");
  }
}

Future<bool> desvincularMercadoPago() async {
  //todo cuando actualizemos el vincular
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.post(
    Uri.parse("$baseUrl/mercadopago/delete"),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    return false;
  }
  return true;
}

Future<List<dynamic>> obtenerMetodosDePago() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  final response = await http.get(
    Uri.parse("$baseUrl/mercadopago/payment-methods"),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': "Bearer $token",
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    throw Exception('Error al obtener métodos de pago: ${response.body}');
  }
}
