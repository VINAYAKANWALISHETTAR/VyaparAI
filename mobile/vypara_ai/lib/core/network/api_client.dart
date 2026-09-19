import 'package:dio/dio.dart';
import 'package:vypara_ai/core/constants/app_constants.dart';

/// Central HTTP client for the entire application.
///
/// All network communication must go through this client.
/// Feature-specific API methods must NOT be added here.
/// Those belong in feature-specific services/datasources.
class ApiClient {
  late final Dio dio;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (AppConstants.enableLogging) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: true,
      ));
    }
  }
}
