import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static final String _baseUrl = "http://127.0.0.1:8000/api";

  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    print("entramos al login");

    final response = await http.post(
      Uri.parse("$_baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    print(response);

    if (response.statusCode == 200) {
      print("200");
      return jsonDecode(
        response.body,
      ); // Devuelve el mapa con accessToken y uuid
    } else {
      print(response.statusCode);
      return null; // Devuelve null si el inicio de sesión falla
    }
  }

  //TODO PEDIR NOMBRE Y APELLIDO
  static Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
  }) async {
    print("Entramos al register");

    final response = await http.post(
      Uri.parse("$_baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": "pepe",
        "last_name": "Rodriguez",
        "email": email,
        "password": password,
      }),
    );

    print(response);

    if (response.statusCode == 201) {
      print("Usuario registrado con éxito");
      return jsonDecode(response.body); // Devuelve accessToken
    } else {
      print("Fallo el registro: ${response.statusCode}");
      print("Cuerpo: ${response.body}");
      return null;
    }
  }
}
