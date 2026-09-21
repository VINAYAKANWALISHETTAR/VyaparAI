import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/notifications/data/models/notification_model.dart';

class NotificationsRemoteDataSource {
  final ApiClient apiClient;

  NotificationsRemoteDataSource(this.apiClient);

  Future<List<AppNotificationModel>> getNotifications({bool unreadOnly = false}) async {
    try {
      final response = await apiClient.dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'unread_only': unreadOnly},
      );
      if (response.data is List) {
        return (response.data as List)
            .map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await apiClient.dio.patch(
        '${ApiEndpoints.notifications}$id/read',
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await apiClient.dio.patch(
        '${ApiEndpoints.notifications}mark-all-read',
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await apiClient.dio.delete(
        '${ApiEndpoints.notifications}$id',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
