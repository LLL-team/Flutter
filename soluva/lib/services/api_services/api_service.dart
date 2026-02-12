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
import 'package:soluva/services/api_services/schedule_service.dart';

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

  static Future<bool> verifyToken() async {
    return await AuthService.verifyToken();
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

  ///Obtiene las notificaciones (Como esta en el perfil lo pongo aca sino lo movemos a otro servicio)
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    return await ProfileService.getNotifications();
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
    required Map<String, dynamic> trade,
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
  static Future<List<Map<String, dynamic>>> getWorkerServices(
    String uuid,
  ) async {
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

  /// Actualiza el precio de un servicio del trabajador
  static Future<bool> updateWorkerServiceCost({
    required String service,
    required String category,
    required double cost,
  }) async {
    return await WorkerService.updateWorkerServiceCost(
      service: service,
      category: category,
      cost: cost,
    );
  }

  // ==================== HORARIOS DEL TRABAJADOR ====================

  /// Obtiene los horarios de un trabajador
  static Future<List<Map<String, dynamic>>> getWorkerSchedule(
    String uuid,
  ) async {
    return await WorkerService.getWorkerSchedule(uuid);
  }

  /// Actualiza los horarios del trabajador
  static Future<bool> updateWorkerSchedule({
    required List<Map<String, String>> schedule,
  }) async {
    return await WorkerService.updateWorkerSchedule(schedule: schedule);
  }

  // ==================== SOLICITUDES ====================

  /// Obtiene las solicitudes del usuario actual
  static Future<Map<String, dynamic>> getMyRequests() async {
    return await RequestService.getMyRequests();
  }

  /// Obtiene las solicitudes creadas por el usuario (paginadas)
  static Future<Map<String, dynamic>> getUserRequests({int page = 1}) async {
    return await RequestService.getUserRequests(page: page);
  }

  /// Obtiene las solicitudes asignadas al trabajador (paginadas)
  static Future<Map<String, dynamic>> getWorkerRequests({int page = 1}) async {
    return await RequestService.getWorkerRequests(page: page);
  }

  /// Cambia el estado de una solicitud
  static Future<Map<String, dynamic>> changeRequestStatus({
    required String uuid,
    required String status,
  }) async {
    return await RequestService.changeStatus(uuid: uuid, status: status);
  }

  /// Obtiene una solicitud por su UUID
  static Future<Map<String, dynamic>?> getRequestById(String uuid) async {
    return await RequestService.getRequestById(uuid);
  }

  /// Crea una calificación para una solicitud
  static Future<Map<String, dynamic>> createRating({
    required String requestUuid,
    required int workQuality,
    required int punctuality,
    required int friendliness,
    String? review,
  }) async {
    return await RequestService.createRating(
      requestUuid: requestUuid,
      workQuality: workQuality,
      punctuality: punctuality,
      friendliness: friendliness,
      review: review,
    );
  }

  /// Procesa un pago con Mercado Pago
  static Future<Map<String, dynamic>> processPayment({
    required String requestUuid,
    required String cardToken,
    required String paymentMethodId,
  }) async {
    return await RequestService.payment(requestUuid, cardToken, paymentMethodId);
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
    return await RequestService.createRequest(
      location: location,
      date: date,
      type: type,
      subtype: subtype,
      workerUuid: workerUuid,
      startAt: startAt,
      amount: amount,
      description: description,
    );
  }

  // ==================== HORARIOS (SCHEDULE SERVICE) ====================

  /// Obtiene los horarios de un trabajador (via ScheduleService)
  static Future<Map<String, dynamic>> getSchedules(String uuid) async {
    return await ScheduleService.getSchedules(uuid);
  }

  /// Reemplaza los horarios del trabajador
  static Future<Map<String, dynamic>> replaceSchedules(
    Map<String, List<Map<String, String>>> schedulesByDay,
  ) async {
    return await ScheduleService.replaceSchedules(schedulesByDay);
  }

  // ==================== TOKEN FCM ====================
  /// Envía el token FCM al servidor
  static Future<void> sendFCMTokenToServer(String token) async {
    return await UserService.sendFCMTokenToServer(token);
  }
}
