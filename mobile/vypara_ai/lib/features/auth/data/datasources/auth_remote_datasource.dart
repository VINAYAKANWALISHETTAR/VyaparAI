import 'package:dio/dio.dart';
import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/core/errors/app_exception.dart';
import 'package:vypara_ai/core/errors/network_exception.dart';
import 'package:vypara_ai/features/auth/data/models/login_request.dart';
import 'package:vypara_ai/features/auth/data/models/login_response.dart';
import 'package:vypara_ai/features/auth/data/models/register_request.dart';

class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource(this.apiClient);

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (e) {
      throw const UnknownException('Login failed');
    }
  }

  Future<void> register(RegisterRequest request) async {
    try {
      await apiClient.dio.post(ApiEndpoints.register, data: request.toJson());
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (_) {
      throw const UnknownException('Registration failed');
    }
  }
}
