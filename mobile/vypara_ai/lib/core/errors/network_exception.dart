import 'package:dio/dio.dart';

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const NetworkException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory NetworkException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Connection timeout. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'Server error occurred.';
        if (data is Map && data.containsKey('detail')) {
          message = data['detail'].toString();
        } else if (error.message != null) {
          message = error.message!;
        }
        return NetworkException(message: message, statusCode: statusCode, data: data);
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection.');
      default:
        return NetworkException(message: error.message ?? 'An unexpected error occurred.');
    }
  }
}
