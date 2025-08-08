import 'dart:io';
import 'dart:typed_data';
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

  static Future<void> uploadProfileImage(String path) async {
    await UserService.uploadProfileImage(path);
  }

  static Future getFoto(String uuid) async {
    return UserService.getFoto(uuid);
  }

  static Future<Map<String, dynamic>> enviarSolicitudTrabajador({
    required String nationalId,
    required Map<String, List<String>> trade,
    required String taskDescription,
    String? description,
    File? facePhoto,
    required certifications,
    required String token,
    required Uint8List? webImageBytes,
  }) {
    print("Sending worker application...");
    print("National ID: $nationalId");
    print("Trade: $trade");
    print("Task Description: $taskDescription");
    print("Description: $description");
    print("Face Photo: ${facePhoto?.path}");
    print("Web Image Bytes: ${webImageBytes != null}");
    return WorkerService.enviarSolicitudTrabajador(
      nationalId: nationalId,
      trade: trade,
      taskDescription: taskDescription,
      description: description,
      facePhoto: facePhoto,
      certifications: certifications,
      token: token,
      webImageBytes: webImageBytes,
    );
  }

  static Future<Map<String, List<String>>> getServices() async {
    return UtilsService.getServices();
  }
}
