import 'package:vypara_ai/features/reminders/data/datasources/reminders_remote_datasource.dart';
import 'package:vypara_ai/features/reminders/data/models/reminder_model.dart';
import 'package:vypara_ai/features/reminders/repositories/reminders_repository.dart';

class RemindersRepositoryImpl implements RemindersRepository {
  final RemindersRemoteDataSource _remoteDataSource;

  RemindersRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ReminderModel>> getReminders({String? status}) {
    return _remoteDataSource.getReminders(status: status);
  }

  @override
  Future<ReminderModel> createReminder({
    required String title,
    required String description,
    DateTime? dueAt,
    double? amount,
    String? partyName,
    String? reminderType,
  }) {
    return _remoteDataSource.createReminder(
      title: title,
      description: description,
      dueAt: dueAt,
      amount: amount,
      partyName: partyName,
      reminderType: reminderType,
    );
  }

  @override
  Future<ReminderModel> updateReminderStatus({
    required String reminderId,
    required String status,
  }) {
    return _remoteDataSource.updateReminderStatus(
      reminderId: reminderId,
      status: status,
    );
  }

  @override
  Future<void> deleteReminder(String reminderId) {
    return _remoteDataSource.deleteReminder(reminderId);
  }
}
