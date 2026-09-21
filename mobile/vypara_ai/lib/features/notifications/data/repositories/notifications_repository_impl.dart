import 'package:vypara_ai/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:vypara_ai/features/notifications/data/models/notification_model.dart';
import 'package:vypara_ai/features/notifications/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;

  NotificationsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<AppNotificationModel>> getNotifications({bool unreadOnly = false}) {
    return remoteDataSource.getNotifications(unreadOnly: unreadOnly);
  }

  @override
  Future<bool> markAsRead(String id) {
    return remoteDataSource.markAsRead(id);
  }

  @override
  Future<bool> markAllAsRead() {
    return remoteDataSource.markAllAsRead();
  }

  @override
  Future<bool> deleteNotification(String id) {
    return remoteDataSource.deleteNotification(id);
  }
}
