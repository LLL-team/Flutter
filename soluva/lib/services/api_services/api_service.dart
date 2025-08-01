import 'user_service.dart';

class ApiService {
  static Future<Map<String, dynamic>?> getUserProfile() {
    return UserService.getUserProfile();
  }

  static Future<bool> editUserProfile({
    required String name,
    required String lastName,
    String? descripcion,
  }) {
    return UserService.editUserProfile(
      name: name,
      lastName: lastName,
      descripcion: descripcion,
    );
  }
}
