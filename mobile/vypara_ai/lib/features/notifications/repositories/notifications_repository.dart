import 'package:vypara_ai/features/notifications/data/models/notification_model.dart';

abstract class NotificationsRepository {
  Future<List<AppNotificationModel>> getNotifications({bool unreadOnly = false});
  Future<bool> markAsRead(String id);
  Future<bool> markAllAsRead();
  Future<bool> deleteNotification(String id);
}
