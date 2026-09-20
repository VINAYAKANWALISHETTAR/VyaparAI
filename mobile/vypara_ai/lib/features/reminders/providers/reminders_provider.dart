import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:vypara_ai/features/reminders/data/models/reminder_model.dart';
import 'package:vypara_ai/features/reminders/data/repositories/reminders_repository_impl.dart';
import 'package:vypara_ai/features/reminders/repositories/reminders_repository.dart';

class RemindersState {
  final bool isLoading;
  final String? error;
  final List<ReminderModel> upcomingReminders;
  final List<ReminderModel> completedReminders;

  const RemindersState({
    this.isLoading = false,
    this.error,
    this.upcomingReminders = const [],
    this.completedReminders = const [],
  });

  RemindersState copyWith({
    bool? isLoading,
    String? error,
    List<ReminderModel>? upcomingReminders,
    List<ReminderModel>? completedReminders,
  }) {
    return RemindersState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      upcomingReminders: upcomingReminders ?? this.upcomingReminders,
      completedReminders: completedReminders ?? this.completedReminders,
    );
  }
}

class RemindersProvider extends Notifier<RemindersState> {
  late final RemindersRepository repository;

  @override
  RemindersState build() {
    repository = RemindersRepositoryImpl(
      RemindersRemoteDataSource(ApiClient()),
    );
    Future.microtask(() => loadReminders());
    return const RemindersState(isLoading: true);
  }

  Future<void> loadReminders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final allReminders = await repository.getReminders();
      final upcoming = allReminders.where((r) => r.status != 'completed').toList();
      final completed = allReminders.where((r) => r.status == 'completed').toList();

      state = state.copyWith(
        isLoading: false,
        upcomingReminders: upcoming,
        completedReminders: completed,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createReminder({
    required String title,
    required String description,
    DateTime? dueAt,
    double? amount,
    String? partyName,
    String? reminderType,
  }) async {
    try {
      final created = await repository.createReminder(
        title: title,
        description: description,
        dueAt: dueAt,
        amount: amount,
        partyName: partyName,
        reminderType: reminderType,
      );

      state = state.copyWith(
        upcomingReminders: [created, ...state.upcomingReminders],
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<void> toggleReminderStatus(ReminderModel reminder) async {
    final newStatus = reminder.isCompleted ? 'pending' : 'completed';
    try {
      final updated = await repository.updateReminderStatus(
        reminderId: reminder.id,
        status: newStatus,
      );

      if (newStatus == 'completed') {
        state = state.copyWith(
          upcomingReminders: state.upcomingReminders.where((r) => r.id != reminder.id).toList(),
          completedReminders: [updated, ...state.completedReminders],
        );
      } else {
        state = state.copyWith(
          completedReminders: state.completedReminders.where((r) => r.id != reminder.id).toList(),
          upcomingReminders: [updated, ...state.upcomingReminders],
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      await repository.deleteReminder(reminderId);
      state = state.copyWith(
        upcomingReminders: state.upcomingReminders.where((r) => r.id != reminderId).toList(),
        completedReminders: state.completedReminders.where((r) => r.id != reminderId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final remindersProvider =
    NotifierProvider<RemindersProvider, RemindersState>(RemindersProvider.new);
