import 'package:dio/dio.dart';
import 'package:vypara_ai/core/errors/app_exception.dart';

class NetworkException extends AppException {
  final int? statusCode;
  final dynamic data;

  const NetworkException({
    required String message,
    this.statusCode,
    this.data,
  }) : super(message);

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
        return const NetworkException(
            message: 'Unable to connect to backend server. Please check your internet connection or try again.');
      default:
        return NetworkException(message: error.message ?? 'An unexpected network error occurred.');
    }
  }
}
