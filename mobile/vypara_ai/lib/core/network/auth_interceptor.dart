import 'package:dio/dio.dart';
import 'package:vypara_ai/core/storage/storage_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  final StorageService storage;

  AuthInterceptor({
    required this.dio,
    StorageService? storage,
  }) : storage = storage ?? StorageService();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await storage.clearAll();
    }
    return handler.next(err);
  }
}
