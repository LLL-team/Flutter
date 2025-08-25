import 'dart:io';
import 'dart:typed_data';
import 'package:http/src/response.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:soluva/services/api_services/auth_service.dart';
import 'package:soluva/services/api_services/profile_service.dart';
import 'package:soluva/services/api_services/user_service.dart';
import 'package:soluva/services/api_services/utils_service.dart';
import 'package:soluva/services/api_services/worker_service.dart';

class ApiService {
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    print(prefs.getString('auth_token'));
    return prefs.getString('auth_token');
  }

  static Future<bool> editUserProfile({
    required String name,
    required String lastName,
    String? descripcion,
  }) {
    return ProfileService.editUserProfile(
      name: name,
      lastName: lastName,
      descripcion: descripcion,
    );
  }

  static Future<Map<String, dynamic>?> getUserProfile() {
    return ProfileService.getUserProfile();
  }

  static Future<void> logout() async {
    await AuthService.logout();
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await AuthService.login(email: email, password: password);

    if (response == null) {
      throw Exception('Login failed');
    }

    // Aquí podrías manejar la respuesta, como redirigir al usuario
  }

  static Future<void> register({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {
    await AuthService.register(
      email: email,
      password: password,
      name: name,
      lastName: lastName,
    );
  }

  static Future<void> uploadProfileImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    await UserService.uploadProfileImage(imageBytes, fileName);
  }

  static Future getFoto(String uuid) async {
    return UserService.getFoto(uuid);
  }

  static Future<Response> enviarSolicitudTrabajador({
    required String nationalId,
    required Map<String, List<String>> trade,
    required String taskDescription,
    String? description,
    File? facePhoto,
    Uint8List? webImageBytes,
    File? certifications,
    Uint8List? webCertificationBytes,
    required String token,
  }) {
    return WorkerService.enviarSolicitudTrabajador(
      nationalId: nationalId,
      trade: trade,
      taskDescription: taskDescription,
      description: description,
      facePhoto: facePhoto,
      webImageBytes: webImageBytes,
      certifications: certifications,
      webCertificationBytes: webCertificationBytes, // ← pasa el parámetro
      token: token,
    );
  }

  static Future<Map<String, List<String>>> getServices() async {
    return UtilsService.getServices();
  }

  static Future<Map<String, dynamic>> getStatus() async {
    return WorkerService.getStatus();
  }

  workers() {}
}
