import 'package:vypara_ai/core/network/api_client.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  Future<void> login(String email, String password) async {
    // Future: implement login using apiClient.dio.post(ApiEndpoints.login, ...)
  }

  Future<void> logout() async {
    // Future: implement logout
  }

  Future<void> refreshToken() async {
    // Future: implement token refresh
  }
}
