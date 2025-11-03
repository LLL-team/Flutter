import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:soluva/services/api_services/auth_service.dart';
import 'package:soluva/services/api_services/profile_service.dart';
import 'package:soluva/services/api_services/user_service.dart';
import 'package:soluva/services/api_services/utils_service.dart';
import 'package:soluva/services/api_services/worker_service.dart';
import 'package:soluva/services/api_services/request_service.dart';

/// Clase centralizada para todas las llamadas a servicios
/// TODAS las pantallas deben usar esta clase en lugar de llamar directamente a los servicios
class ApiService {
  // ==================== TOKEN & AUTH ====================
  
  /// Obtiene el token de autenticación almacenado
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Verifica si el usuario está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Inicia sesión con email y contraseña
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    return await AuthService.login(email: email, password: password);
  }

  /// Registra un nuevo usuario
  static Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String name,
    required String lastName,
  }) async {
    return await AuthService.register(
      email: email,
      password: password,
      name: name,
      lastName: lastName,
    );
  }

  /// Cierra sesión del usuario
  static Future<void> logout() async {
    await AuthService.logout();
  }

  // ==================== PERFIL DE USUARIO ====================

  /// Obtiene el perfil del usuario actual
  static Future<Map<String, dynamic>?> getUserProfile() async {
    return await ProfileService.getUserProfile();
  }

  /// Edita el perfil del usuario
  static Future<bool> editUserProfile({
    required String? name,
    required String? lastName,
    String? descripcion,
  }) async {
    return await ProfileService.editUserProfile(
      name: name,
      lastName: lastName,
      descripcion: descripcion,
    );
  }

  // ==================== IMÁGENES ====================

  /// Sube una imagen de perfil
  static Future<void> uploadProfileImage(
    Uint8List imageBytes,
    String fileName,
  ) async {
    await UserService.uploadProfileImage(imageBytes, fileName);
  }

  /// Obtiene la foto de un usuario por UUID
  static Future<Uint8List?> getFoto(String uuid) async {
    return await UserService.getFoto(uuid);
  }

  // ==================== SERVICIOS ====================

  /// Obtiene todos los servicios disponibles (estructura de 3 niveles)
  static Future<Map<String, dynamic>> getServices() async {
    return await UtilsService.getServices();
  }

  // ==================== TRABAJADORES ====================

  /// Envía una solicitud para convertirse en trabajador
  static Future<http.Response> enviarSolicitudTrabajador({
    required String nationalId,
    required Map<String, List<String>> trade,
    required String taskDescription,
    String? description,
    File? facePhoto,
    Uint8List? webImageBytes,
    File? certifications,
    Uint8List? webCertificationBytes,
    required String token,
  }) async {
    return await WorkerService.enviarSolicitudTrabajador(
      nationalId: nationalId,
      trade: trade,
      taskDescription: taskDescription,
      description: description,
      facePhoto: facePhoto,
      webImageBytes: webImageBytes,
      certifications: certifications,
      webCertificationBytes: webCertificationBytes,
      token: token,
    );
  }

  /// Obtiene el estado de la solicitud de trabajador
  static Future<Map<String, dynamic>> getWorkerStatus() async {
    return await WorkerService.getStatus();
  }

  /// Obtiene trabajadores por categoría/subcategoría
  static Future<List<dynamic>> getWorkersByCategory(String category) async {
    return await WorkerService.getWorkersByCategory(category);
  }

  /// Obtiene información de un trabajador específico por UUID
  static Future<Map<String, dynamic>> getWorkerByUuid(String uuid) async {
    return await WorkerService.getWorkerByUuid(uuid);
  }

  // ==================== SERVICIOS DEL TRABAJADOR ====================

  /// Obtiene los servicios de un trabajador específico
  static Future<List<Map<String, dynamic>>> getWorkerServices(String uuid) async {
    return await WorkerService.getWorkerServices(uuid);
  }

  /// Agrega un nuevo servicio al perfil del trabajador
  static Future<Map<String, dynamic>> addWorkerService({
    required String type,
    required String category,
    required String service,
    required double cost,
  }) async {
    return await WorkerService.addWorkerService(
      type: type,
      category: category,
      service: service,
      cost: cost,
    );
  }

  // ==================== SOLICITUDES ====================

  /// Obtiene las solicitudes del usuario actual
  static Future<List<Map<String, dynamic>>> getMyRequests() async {
    return await RequestService.getMyRequests();
  }
}