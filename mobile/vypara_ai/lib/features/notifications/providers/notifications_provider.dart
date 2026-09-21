import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:vypara_ai/features/notifications/data/models/notification_model.dart';
import 'package:vypara_ai/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:vypara_ai/features/notifications/repositories/notifications_repository.dart';

class NotificationsState {
  final bool isLoading;
  final List<AppNotificationModel> notifications;
  final bool unreadOnly;
  final String? error;

  const NotificationsState({
    this.isLoading = false,
    this.notifications = const [],
    this.unreadOnly = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.read).length;

  List<AppNotificationModel> get filteredNotifications {
    if (unreadOnly) {
      return notifications.where((n) => !n.read).toList();
    }
    return notifications;
  }

  NotificationsState copyWith({
    bool? isLoading,
    List<AppNotificationModel>? notifications,
    bool? unreadOnly,
    String? error,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      error: error,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  late final NotificationsRepository _repository;

  @override
  NotificationsState build() {
    _repository = NotificationsRepositoryImpl(
      NotificationsRemoteDataSource(ApiClient()),
    );
    Future.microtask(() => loadNotifications());
    return const NotificationsState(isLoading: true);
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repository.getNotifications();
      state = state.copyWith(isLoading: false, notifications: list);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load notifications');
    }
  }

  void setUnreadOnly(bool value) {
    state = state.copyWith(unreadOnly: value);
  }

  Future<void> markAsRead(String id) async {
    // Optimistic update
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return n.copyWith(read: true);
      }
      return n;
    }).toList();
    state = state.copyWith(notifications: updated);

    await _repository.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    // Optimistic update
    final updated = state.notifications.map((n) => n.copyWith(read: true)).toList();
    state = state.copyWith(notifications: updated);

    await _repository.markAllAsRead();
  }

  Future<bool> deleteNotification(String id) async {
    // Optimistic remove
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(notifications: updated);

    return await _repository.deleteNotification(id);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(NotificationsNotifier.new);
