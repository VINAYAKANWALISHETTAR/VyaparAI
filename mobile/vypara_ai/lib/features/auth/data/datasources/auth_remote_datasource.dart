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

  Future<LoginResponse> register(RegisterRequest request) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('access_token')) {
        return LoginResponse.fromJson(data);
      }
      // Fallback if endpoint returns user_id
      return login(LoginRequest(email: request.email, password: request.password));
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (_) {
      throw const UnknownException('Registration failed');
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim().toLowerCase()},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (_) {
      throw const UnknownException('Password reset request failed');
    }
  }

  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'token': token.trim(),
          'new_password': newPassword,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw NetworkException.fromDioError(e);
    } catch (_) {
      throw const UnknownException('Password reset failed');
    }
  }
}
