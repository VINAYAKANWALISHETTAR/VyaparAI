import 'package:dio/dio.dart';
import 'package:vypara_ai/core/constants/app_constants.dart';
import 'package:vypara_ai/core/network/auth_interceptor.dart';
import 'package:vypara_ai/core/storage/storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio dio;

  ApiClient._internal() {
    final storage = StorageService();
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
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

    dio.interceptors.add(AuthInterceptor(dio: dio, storage: storage));
  }
}
