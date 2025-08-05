import 'dart:io';

import 'package:soluva/services/api_services/auth_service.dart';
import 'package:soluva/services/api_services/profile_service.dart';
import 'package:soluva/services/api_services/user_service.dart';
import 'package:soluva/services/api_services/worker_service.dart';

class ApiService {
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

  static void enviarSolicitudTrabajador({
    required String nationalId,
    required String trade,
    required String taskDescription,
    String? description,
    File? facePhoto,
    required certifications,
    required String token,
  }) {
    WorkerService.enviarSolicitudTrabajador(
      nationalId: nationalId,
      trade: trade,
      taskDescription: taskDescription,
      description: description,
      facePhoto: facePhoto,
      certifications: certifications,
      token: token,
    );
  }
}
